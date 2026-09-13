use nusacode::{check, Interpreter, NusaError};
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::Path;
use std::process::ExitCode;

const HELP: &str = "NusaCode reference interpreter

Penggunaan:
  nusa run <file>     Jalankan berkas .nusa
  nusa <file>         Jalankan berkas .nusa
  nusa check <file>   Periksa sintaksis tanpa menjalankan
  nusa repl           Mulai REPL interaktif
  nusa --version      Tampilkan versi
  nusa --help         Tampilkan bantuan
";

fn main() -> ExitCode {
    match dispatch(env::args().skip(1).collect()) {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("{error}");
            ExitCode::FAILURE
        }
    }
}

fn dispatch(args: Vec<String>) -> Result<(), String> {
    match args.as_slice() {
        [] => Err(format!("Argumen belum diberikan.\n\n{HELP}")),
        [flag] if flag == "--help" || flag == "-h" => {
            print!("{HELP}");
            Ok(())
        }
        [flag] if flag == "--version" || flag == "-V" => {
            println!("nusa {}", env!("CARGO_PKG_VERSION"));
            Ok(())
        }
        [command] if command == "repl" => repl(),
        [command, file] if command == "run" => run_file(file),
        [command, file] if command == "check" => check_file(file),
        [file] if !file.starts_with('-') => run_file(file),
        _ => Err(format!("Perintah atau argumen tidak dikenal.\n\n{HELP}")),
    }
}

fn validate_path(file: &str) -> Result<(), String> {
    if Path::new(file).extension().and_then(|value| value.to_str()) != Some("nusa") {
        return Err(format!("Berkas harus memakai ekstensi .nusa: {file}"));
    }
    Ok(())
}

fn read_source(file: &str) -> Result<String, String> {
    validate_path(file)?;
    fs::read_to_string(file).map_err(|error| format!("Tidak dapat membaca '{file}': {error}"))
}

fn run_file(file: &str) -> Result<(), String> {
    let source = read_source(file)?;
    let mut interpreter = Interpreter::new();
    interpreter.execute(&source).map_err(format_error)?;
    print!("{}", interpreter.take_output());
    Ok(())
}

fn check_file(file: &str) -> Result<(), String> {
    let source = read_source(file)?;
    check(&source).map_err(format_error)?;
    println!("Sintaksis valid: {file}");
    Ok(())
}

fn format_error(error: NusaError) -> String {
    error.to_string()
}

fn repl() -> Result<(), String> {
    println!(
        "Nusa REPL {}. Ketik 'keluar' untuk berhenti.",
        env!("CARGO_PKG_VERSION")
    );
    let stdin = io::stdin();
    let mut interpreter = Interpreter::new();
    let mut buffer = String::new();
    loop {
        print!("{}", if buffer.is_empty() { ">>> " } else { "... " });
        io::stdout()
            .flush()
            .map_err(|error| format!("Gagal menulis keluaran: {error}"))?;
        let mut line = String::new();
        if stdin
            .read_line(&mut line)
            .map_err(|error| format!("Gagal membaca masukan: {error}"))?
            == 0
        {
            break;
        }
        if buffer.is_empty() && matches!(line.trim(), "keluar" | "exit" | "quit") {
            break;
        }
        buffer.push_str(&line);
        match interpreter.execute(&buffer) {
            Ok(()) => {
                print!("{}", interpreter.take_output());
                buffer.clear();
            }
            Err(NusaError::Parse(error)) if error.incomplete => continue,
            Err(error) => {
                eprintln!("{error}");
                buffer.clear();
            }
        }
    }
    Ok(())
}
