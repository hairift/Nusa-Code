//! Portable reference interpreter for the Nusa language.

mod lexer;
mod parser;
mod runtime;

pub use lexer::{lex, LexError, Position, Token, TokenKind};
pub use parser::{parse, ParseError, Program};
pub use runtime::{Interpreter, RuntimeError, Value};

use std::fmt;

/// An error produced by one of the interpreter's front-end or runtime stages.
#[derive(Debug)]
pub enum NusaError {
    Lex(LexError),
    Parse(ParseError),
    Runtime(RuntimeError),
}

impl fmt::Display for NusaError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Lex(error) => write!(f, "Kesalahan leksikal: {error}"),
            Self::Parse(error) => write!(f, "Kesalahan sintaksis: {error}"),
            Self::Runtime(error) => write!(f, "Kesalahan saat berjalan: {error}"),
        }
    }
}

impl std::error::Error for NusaError {}

impl From<LexError> for NusaError {
    fn from(value: LexError) -> Self {
        Self::Lex(value)
    }
}

impl From<ParseError> for NusaError {
    fn from(value: ParseError) -> Self {
        Self::Parse(value)
    }
}

impl From<RuntimeError> for NusaError {
    fn from(value: RuntimeError) -> Self {
        Self::Runtime(value)
    }
}

/// Parse source without executing it.
pub fn check(source: &str) -> Result<Program, NusaError> {
    let tokens = lex(source)?;
    Ok(parse(tokens)?)
}

/// Execute source in a fresh interpreter and return captured output.
pub fn run(source: &str) -> Result<String, NusaError> {
    let mut interpreter = Interpreter::new();
    interpreter.execute(source)?;
    Ok(interpreter.take_output())
}
