use crate::lexer::Position;
use crate::parser::{parse, BinaryOp, Expr, ExprKind, Program, Stmt, StmtKind, UnaryOp};
use crate::{lex, NusaError};
use std::cell::RefCell;
use std::collections::{BTreeMap, HashMap};
use std::fmt;
use std::io;
use std::rc::Rc;

#[derive(Clone)]
pub enum Value {
    Integer(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Null,
    List(Vec<Value>),
    Map(BTreeMap<String, Value>),
    Function(Rc<Function>),
    Builtin(Builtin),
}

#[derive(Clone)]
pub struct Function {
    name: String,
    parameters: Vec<String>,
    body: Vec<Stmt>,
    closure: Environment,
}

#[derive(Clone, Copy)]
pub enum Builtin {
    Print,
    PrintInline,
    Length,
    ToString,
    ToInteger,
    ToFloat,
    Input,
    Type,
    Push,
    Absolute,
}

impl fmt::Debug for Value {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{self}")
    }
}

impl fmt::Display for Value {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Integer(value) => write!(f, "{value}"),
            Self::Float(value) => {
                let text = value.to_string();
                write!(f, "{text}")
            }
            Self::String(value) => write!(f, "{value}"),
            Self::Bool(true) => write!(f, "benar"),
            Self::Bool(false) => write!(f, "salah"),
            Self::Null => write!(f, "kosong"),
            Self::List(values) => {
                write!(f, "[")?;
                for (index, value) in values.iter().enumerate() {
                    if index > 0 {
                        write!(f, ", ")?;
                    }
                    match value {
                        Self::String(text) => write!(f, "\"{text}\"")?,
                        _ => write!(f, "{value}")?,
                    }
                }
                write!(f, "]")
            }
            Self::Map(entries) => {
                write!(f, "{{")?;
                for (index, (key, value)) in entries.iter().enumerate() {
                    if index > 0 {
                        write!(f, ", ")?;
                    }
                    write!(f, "\"{key}\": {value}")?;
                }
                write!(f, "}}")
            }
            Self::Function(function) => write!(f, "<fungsi {}>", function.name),
            Self::Builtin(_) => write!(f, "<fungsi bawaan>"),
        }
    }
}

impl PartialEq for Value {
    fn eq(&self, other: &Self) -> bool {
        match (self, other) {
            (Self::Integer(a), Self::Integer(b)) => a == b,
            (Self::Float(a), Self::Float(b)) => a == b,
            (Self::Integer(a), Self::Float(b)) => *a as f64 == *b,
            (Self::Float(a), Self::Integer(b)) => *a == *b as f64,
            (Self::String(a), Self::String(b)) => a == b,
            (Self::Bool(a), Self::Bool(b)) => a == b,
            (Self::Null, Self::Null) => true,
            (Self::List(a), Self::List(b)) => a == b,
            (Self::Map(a), Self::Map(b)) => a == b,
            _ => false,
        }
    }
}

#[derive(Clone)]
struct Environment(Rc<RefCell<Scope>>);

struct Scope {
    values: HashMap<String, Value>,
    parent: Option<Environment>,
}

impl Environment {
    fn new() -> Self {
        Self(Rc::new(RefCell::new(Scope {
            values: HashMap::new(),
            parent: None,
        })))
    }
    fn child(&self) -> Self {
        Self(Rc::new(RefCell::new(Scope {
            values: HashMap::new(),
            parent: Some(self.clone()),
        })))
    }
    fn define(&self, name: impl Into<String>, value: Value) {
        self.0.borrow_mut().values.insert(name.into(), value);
    }
    fn get(&self, name: &str) -> Option<Value> {
        let scope = self.0.borrow();
        scope
            .values
            .get(name)
            .cloned()
            .or_else(|| scope.parent.as_ref().and_then(|parent| parent.get(name)))
    }
    fn assign(&self, name: &str, value: Value) -> bool {
        if self.0.borrow().values.contains_key(name) {
            self.0.borrow_mut().values.insert(name.into(), value);
            true
        } else {
            let parent = self.0.borrow().parent.clone();
            parent.is_some_and(|parent| parent.assign(name, value))
        }
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct RuntimeError {
    pub message: String,
    pub position: Position,
}

impl fmt::Display for RuntimeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.message, self.position)
    }
}
impl std::error::Error for RuntimeError {}

enum Flow {
    Continue,
    Return(Value),
}

pub struct Interpreter {
    globals: Environment,
    output: String,
    call_depth: usize,
}

impl Default for Interpreter {
    fn default() -> Self {
        Self::new()
    }
}

impl Interpreter {
    pub fn new() -> Self {
        let globals = Environment::new();
        for (names, builtin) in [
            (&["tulis", "print"][..], Builtin::Print),
            (&["tulis_tanpa_baris", "print_inline"], Builtin::PrintInline),
            (&["panjang", "length"], Builtin::Length),
            (&["ubah_teks", "string", "to_string"], Builtin::ToString),
            (
                &["ubah_bilangan", "integer", "to_integer"],
                Builtin::ToInteger,
            ),
            (&["ubah_desimal", "float", "to_float"], Builtin::ToFloat),
            (&["baca", "input"], Builtin::Input),
            (&["tipe", "type"], Builtin::Type),
            (&["dorong", "push"], Builtin::Push),
            (&["mutlak", "absolute", "abs"], Builtin::Absolute),
        ] {
            for name in names {
                globals.define(*name, Value::Builtin(builtin));
            }
        }
        Self {
            globals,
            output: String::new(),
            call_depth: 0,
        }
    }

    pub fn execute(&mut self, source: &str) -> Result<(), NusaError> {
        let program = parse(lex(source)?)?;
        self.execute_program(&program)?;
        Ok(())
    }

    pub fn execute_program(&mut self, program: &Program) -> Result<(), RuntimeError> {
        match self.statements(&program.0, self.globals.clone())? {
            Flow::Continue => Ok(()),
            Flow::Return(_) => Err(RuntimeError {
                message: "'kembalikan/return' hanya boleh dipakai di dalam fungsi".into(),
                position: Position::default(),
            }),
        }
    }

    pub fn output(&self) -> &str {
        &self.output
    }
    pub fn take_output(&mut self) -> String {
        std::mem::take(&mut self.output)
    }

    fn statements(&mut self, statements: &[Stmt], env: Environment) -> Result<Flow, RuntimeError> {
        for statement in statements {
            if let Flow::Return(value) = self.statement(statement, env.clone())? {
                return Ok(Flow::Return(value));
            }
        }
        Ok(Flow::Continue)
    }

    fn statement(&mut self, statement: &Stmt, env: Environment) -> Result<Flow, RuntimeError> {
        match &statement.kind {
            StmtKind::Let(name, expr) => {
                let value = self.expression(expr, env.clone())?;
                env.define(name, value);
            }
            StmtKind::Assign(name, expr) => {
                let value = self.expression(expr, env.clone())?;
                if !env.assign(name, value) {
                    return self.fail(
                        format!("variabel '{name}' tidak didefinisikan"),
                        statement.position,
                    );
                }
            }
            StmtKind::Expression(expr) => {
                self.expression(expr, env)?;
            }
            StmtKind::If {
                branches,
                otherwise,
            } => {
                for (condition, body) in branches {
                    if self.expression(condition, env.clone())?.truthy() {
                        return self.statements(body, env.child());
                    }
                }
                return self.statements(otherwise, env.child());
            }
            StmtKind::While { condition, body } => {
                while self.expression(condition, env.clone())?.truthy() {
                    if let Flow::Return(value) = self.statements(body, env.child())? {
                        return Ok(Flow::Return(value));
                    }
                }
            }
            StmtKind::For {
                name,
                start,
                end,
                step,
                body,
            } => {
                let start = self
                    .expression(start, env.clone())?
                    .integer(statement.position, "nilai awal perulangan")?;
                let end = self
                    .expression(end, env.clone())?
                    .integer(statement.position, "nilai akhir perulangan")?;
                let step = match step {
                    Some(expr) => self
                        .expression(expr, env.clone())?
                        .integer(statement.position, "langkah perulangan")?,
                    None => 1,
                };
                if step == 0 {
                    return self.fail("langkah perulangan tidak boleh nol", statement.position);
                }
                let loop_env = env.child();
                loop_env.define(name, Value::Integer(start));
                let mut current = start;
                while if step > 0 {
                    current <= end
                } else {
                    current >= end
                } {
                    loop_env.assign(name, Value::Integer(current));
                    if let Flow::Return(value) = self.statements(body, loop_env.child())? {
                        return Ok(Flow::Return(value));
                    }
                    current = current.checked_add(step).ok_or_else(|| RuntimeError {
                        message: "bilangan perulangan melampaui jangkauan".into(),
                        position: statement.position,
                    })?;
                }
            }
            StmtKind::Function {
                name,
                parameters,
                body,
            } => {
                let function = Function {
                    name: name.clone(),
                    parameters: parameters.clone(),
                    body: body.clone(),
                    closure: env.clone(),
                };
                env.define(name, Value::Function(Rc::new(function)));
            }
            StmtKind::Return(expr) => {
                let value = match expr {
                    Some(expr) => self.expression(expr, env)?,
                    None => Value::Null,
                };
                return Ok(Flow::Return(value));
            }
        }
        Ok(Flow::Continue)
    }

    fn expression(&mut self, expr: &Expr, env: Environment) -> Result<Value, RuntimeError> {
        match &expr.kind {
            ExprKind::Integer(value) => Ok(Value::Integer(*value)),
            ExprKind::Float(value) => Ok(Value::Float(*value)),
            ExprKind::String(value) => Ok(Value::String(value.clone())),
            ExprKind::Bool(value) => Ok(Value::Bool(*value)),
            ExprKind::Null => Ok(Value::Null),
            ExprKind::Variable(name) => env.get(name).ok_or_else(|| RuntimeError {
                message: format!("nama '{name}' tidak didefinisikan"),
                position: expr.position,
            }),
            ExprKind::List(values) => values
                .iter()
                .map(|value| self.expression(value, env.clone()))
                .collect::<Result<Vec<_>, _>>()
                .map(Value::List),
            ExprKind::Map(entries) => {
                let mut map = BTreeMap::new();
                for (key, value) in entries {
                    let key = self.expression(key, env.clone())?.map_key(key.position)?;
                    let value = self.expression(value, env.clone())?;
                    map.insert(key, value);
                }
                Ok(Value::Map(map))
            }
            ExprKind::Unary(op, value) => {
                let value = self.expression(value, env)?;
                match op {
                    UnaryOp::Not => Ok(Value::Bool(!value.truthy())),
                    UnaryOp::Negate => match value {
                        Value::Integer(value) => {
                            value.checked_neg().map(Value::Integer).ok_or_else(|| {
                                self.error("bilangan bulat melampaui jangkauan", expr.position)
                            })
                        }
                        Value::Float(value) => Ok(Value::Float(-value)),
                        _ => self.fail("operator '-' membutuhkan bilangan", expr.position),
                    },
                }
            }
            ExprKind::Binary(left, BinaryOp::And, right) => {
                let left = self.expression(left, env.clone())?;
                if !left.truthy() {
                    Ok(left)
                } else {
                    self.expression(right, env)
                }
            }
            ExprKind::Binary(left, BinaryOp::Or, right) => {
                let left = self.expression(left, env.clone())?;
                if left.truthy() {
                    Ok(left)
                } else {
                    self.expression(right, env)
                }
            }
            ExprKind::Binary(left, op, right) => {
                let left = self.expression(left, env.clone())?;
                let right = self.expression(right, env)?;
                self.binary(left, *op, right, expr.position)
            }
            ExprKind::Call(callee, arguments) => {
                let callee = self.expression(callee, env.clone())?;
                let arguments = arguments
                    .iter()
                    .map(|arg| self.expression(arg, env.clone()))
                    .collect::<Result<Vec<_>, _>>()?;
                self.call(callee, arguments, expr.position)
            }
            ExprKind::Index(value, index) => {
                let value = self.expression(value, env.clone())?;
                let index = self.expression(index, env)?;
                self.index(value, index, expr.position)
            }
        }
    }

    fn binary(
        &self,
        left: Value,
        op: BinaryOp,
        right: Value,
        position: Position,
    ) -> Result<Value, RuntimeError> {
        match op {
            BinaryOp::Equal => Ok(Value::Bool(left == right)),
            BinaryOp::NotEqual => Ok(Value::Bool(left != right)),
            BinaryOp::Add => match (left, right) {
                (Value::Integer(a), Value::Integer(b)) => a
                    .checked_add(b)
                    .map(Value::Integer)
                    .ok_or_else(|| self.error("hasil penjumlahan melampaui jangkauan", position)),
                (Value::String(a), Value::String(b)) => Ok(Value::String(a + &b)),
                (Value::List(mut a), Value::List(b)) => {
                    a.extend(b);
                    Ok(Value::List(a))
                }
                (a, b) => self.numeric(a, b, position, |a, b| a + b),
            },
            BinaryOp::Subtract => match (left, right) {
                (Value::Integer(a), Value::Integer(b)) => a
                    .checked_sub(b)
                    .map(Value::Integer)
                    .ok_or_else(|| self.error("hasil pengurangan melampaui jangkauan", position)),
                (a, b) => self.numeric(a, b, position, |a, b| a - b),
            },
            BinaryOp::Multiply => match (left, right) {
                (Value::Integer(a), Value::Integer(b)) => a
                    .checked_mul(b)
                    .map(Value::Integer)
                    .ok_or_else(|| self.error("hasil perkalian melampaui jangkauan", position)),
                (a, b) => self.numeric(a, b, position, |a, b| a * b),
            },
            BinaryOp::Divide => {
                let (a, b) = numbers(left, right, position)?;
                if b == 0.0 {
                    self.fail("pembagian dengan nol", position)
                } else {
                    Ok(Value::Float(a / b).normalize())
                }
            }
            BinaryOp::IntegerDivide => {
                let a = left.integer(position, "pembagian bulat")?;
                let b = right.integer(position, "pembagian bulat")?;
                if b == 0 {
                    self.fail("pembagian dengan nol", position)
                } else {
                    a.checked_div(b)
                        .map(Value::Integer)
                        .ok_or_else(|| self.error("hasil pembagian melampaui jangkauan", position))
                }
            }
            BinaryOp::Remainder => {
                let a = left.integer(position, "sisa bagi")?;
                let b = right.integer(position, "sisa bagi")?;
                if b == 0 {
                    self.fail("sisa bagi dengan nol", position)
                } else {
                    a.checked_rem(b)
                        .map(Value::Integer)
                        .ok_or_else(|| self.error("hasil sisa bagi melampaui jangkauan", position))
                }
            }
            BinaryOp::Power => {
                let (a, b) = numbers(left, right, position)?;
                Ok(Value::Float(a.powf(b)).normalize())
            }
            BinaryOp::Less | BinaryOp::LessEqual | BinaryOp::Greater | BinaryOp::GreaterEqual => {
                let ordering = compare(&left, &right, position)?;
                Ok(Value::Bool(match op {
                    BinaryOp::Less => ordering.is_lt(),
                    BinaryOp::LessEqual => ordering.is_le(),
                    BinaryOp::Greater => ordering.is_gt(),
                    BinaryOp::GreaterEqual => ordering.is_ge(),
                    _ => unreachable!(),
                }))
            }
            BinaryOp::And | BinaryOp::Or => unreachable!(),
        }
    }

    fn numeric(
        &self,
        left: Value,
        right: Value,
        position: Position,
        operation: impl FnOnce(f64, f64) -> f64,
    ) -> Result<Value, RuntimeError> {
        let both_integers = matches!(left, Value::Integer(_)) && matches!(right, Value::Integer(_));
        let (a, b) = numbers(left, right, position)?;
        let result = operation(a, b);
        if both_integers
            && result.is_finite()
            && result.fract() == 0.0
            && result >= i64::MIN as f64
            && result <= i64::MAX as f64
        {
            Ok(Value::Integer(result as i64))
        } else {
            Ok(Value::Float(result))
        }
    }

    fn index(&self, value: Value, index: Value, position: Position) -> Result<Value, RuntimeError> {
        match value {
            Value::List(values) => {
                let index = index.integer(position, "indeks daftar")?;
                normalize_index(index, values.len())
                    .and_then(|index| values.get(index).cloned())
                    .ok_or_else(|| self.error("indeks daftar di luar batas", position))
            }
            Value::String(value) => {
                let chars: Vec<char> = value.chars().collect();
                let index = index.integer(position, "indeks teks")?;
                normalize_index(index, chars.len())
                    .and_then(|index| chars.get(index))
                    .map(|ch| Value::String(ch.to_string()))
                    .ok_or_else(|| self.error("indeks teks di luar batas", position))
            }
            Value::Map(values) => {
                let key = index.map_key(position)?;
                values.get(&key).cloned().ok_or_else(|| {
                    self.error(
                        format!("kunci '{key}' tidak ditemukan dalam kamus"),
                        position,
                    )
                })
            }
            _ => self.fail("nilai ini tidak dapat diindeks", position),
        }
    }

    fn call(
        &mut self,
        callee: Value,
        args: Vec<Value>,
        position: Position,
    ) -> Result<Value, RuntimeError> {
        match callee {
            Value::Builtin(builtin) => self.builtin(builtin, args, position),
            Value::Function(function) => {
                if args.len() != function.parameters.len() {
                    return self.fail(
                        format!(
                            "fungsi '{}' membutuhkan {} argumen, menerima {}",
                            function.name,
                            function.parameters.len(),
                            args.len()
                        ),
                        position,
                    );
                }
                if self.call_depth >= 1_000 {
                    return self.fail("batas kedalaman pemanggilan fungsi terlampaui", position);
                }
                let env = function.closure.child();
                for (name, value) in function.parameters.iter().zip(args) {
                    env.define(name, value);
                }
                self.call_depth += 1;
                let result = self.statements(&function.body, env);
                self.call_depth -= 1;
                match result? {
                    Flow::Continue => Ok(Value::Null),
                    Flow::Return(value) => Ok(value),
                }
            }
            _ => self.fail("nilai yang dipanggil bukan fungsi", position),
        }
    }

    fn builtin(
        &mut self,
        builtin: Builtin,
        args: Vec<Value>,
        position: Position,
    ) -> Result<Value, RuntimeError> {
        match builtin {
            Builtin::Print | Builtin::PrintInline => {
                for (index, value) in args.iter().enumerate() {
                    if index > 0 {
                        self.output.push(' ');
                    }
                    self.output.push_str(&value.to_string());
                }
                if matches!(builtin, Builtin::Print) {
                    self.output.push('\n');
                }
                Ok(Value::Null)
            }
            Builtin::Length => {
                one_arg(&args, position, "panjang/length")?;
                let length = match &args[0] {
                    Value::String(value) => value.chars().count(),
                    Value::List(value) => value.len(),
                    Value::Map(value) => value.len(),
                    _ => {
                        return self.fail(
                            "panjang/length membutuhkan teks, daftar, atau kamus",
                            position,
                        )
                    }
                };
                i64::try_from(length)
                    .map(Value::Integer)
                    .map_err(|_| self.error("panjang melampaui jangkauan bilangan", position))
            }
            Builtin::ToString => {
                one_arg(&args, position, "ubah_teks/string")?;
                Ok(Value::String(args[0].to_string()))
            }
            Builtin::ToInteger => {
                one_arg(&args, position, "ubah_bilangan/integer")?;
                match &args[0] {
                    Value::Integer(value) => Ok(Value::Integer(*value)),
                    Value::Float(value) => Ok(Value::Integer(*value as i64)),
                    Value::String(value) => {
                        value.trim().parse().map(Value::Integer).map_err(|_| {
                            self.error(
                                format!("'{value}' tidak dapat diubah menjadi bilangan bulat"),
                                position,
                            )
                        })
                    }
                    Value::Bool(value) => Ok(Value::Integer(i64::from(*value))),
                    _ => self.fail("nilai tidak dapat diubah menjadi bilangan bulat", position),
                }
            }
            Builtin::ToFloat => {
                one_arg(&args, position, "ubah_desimal/float")?;
                match &args[0] {
                    Value::Integer(value) => Ok(Value::Float(*value as f64)),
                    Value::Float(value) => Ok(Value::Float(*value)),
                    Value::String(value) => value.trim().parse().map(Value::Float).map_err(|_| {
                        self.error(
                            format!("'{value}' tidak dapat diubah menjadi desimal"),
                            position,
                        )
                    }),
                    Value::Bool(value) => Ok(Value::Float(if *value { 1.0 } else { 0.0 })),
                    _ => self.fail("nilai tidak dapat diubah menjadi desimal", position),
                }
            }
            Builtin::Input => {
                if args.len() > 1 {
                    return self.fail("baca/input menerima paling banyak satu argumen", position);
                }
                if let Some(prompt) = args.first() {
                    print!("{prompt}");
                }
                let mut line = String::new();
                io::stdin().read_line(&mut line).map_err(|error| {
                    self.error(format!("gagal membaca masukan: {error}"), position)
                })?;
                Ok(Value::String(
                    line.trim_end_matches(['\r', '\n']).to_string(),
                ))
            }
            Builtin::Type => {
                one_arg(&args, position, "tipe/type")?;
                Ok(Value::String(args[0].type_name().into()))
            }
            Builtin::Push => {
                if args.len() != 2 {
                    return self.fail(
                        format!(
                            "dorong/push membutuhkan tepat dua argumen, menerima {}",
                            args.len()
                        ),
                        position,
                    );
                }
                let mut values = match &args[0] {
                    Value::List(values) => values.clone(),
                    _ => return self.fail("argumen pertama dorong/push harus daftar", position),
                };
                values.push(args[1].clone());
                Ok(Value::List(values))
            }
            Builtin::Absolute => {
                one_arg(&args, position, "mutlak/absolute")?;
                match &args[0] {
                    Value::Integer(value) => value
                        .checked_abs()
                        .map(Value::Integer)
                        .ok_or_else(|| self.error("hasil mutlak melampaui jangkauan", position)),
                    Value::Float(value) => Ok(Value::Float(value.abs())),
                    _ => self.fail("mutlak/absolute membutuhkan bilangan", position),
                }
            }
        }
    }

    fn error(&self, message: impl Into<String>, position: Position) -> RuntimeError {
        RuntimeError {
            message: message.into(),
            position,
        }
    }
    fn fail<T>(&self, message: impl Into<String>, position: Position) -> Result<T, RuntimeError> {
        Err(self.error(message, position))
    }
}

impl Value {
    fn truthy(&self) -> bool {
        match self {
            Self::Bool(false) | Self::Null | Self::Integer(0) => false,
            Self::Float(value) => *value != 0.0,
            _ => true,
        }
    }
    fn integer(&self, position: Position, context: &str) -> Result<i64, RuntimeError> {
        match self {
            Self::Integer(value) => Ok(*value),
            _ => Err(RuntimeError {
                message: format!("{context} membutuhkan bilangan bulat"),
                position,
            }),
        }
    }
    fn map_key(&self, position: Position) -> Result<String, RuntimeError> {
        match self {
            Self::String(value) => Ok(value.clone()),
            Self::Integer(value) => Ok(value.to_string()),
            Self::Float(value) => Ok(value.to_string()),
            Self::Bool(value) => Ok(value.to_string()),
            Self::Null => Ok("kosong".into()),
            _ => Err(RuntimeError {
                message: "kunci kamus harus berupa nilai sederhana".into(),
                position,
            }),
        }
    }
    fn normalize(self) -> Self {
        match self {
            Self::Float(value)
                if value.is_finite()
                    && value.fract() == 0.0
                    && value >= i64::MIN as f64
                    && value <= i64::MAX as f64 =>
            {
                Self::Integer(value as i64)
            }
            _ => self,
        }
    }
    fn type_name(&self) -> &'static str {
        match self {
            Self::Integer(_) => "bilangan",
            Self::Float(_) => "desimal",
            Self::String(_) => "teks",
            Self::Bool(_) => "logika",
            Self::Null => "kosong",
            Self::List(_) => "daftar",
            Self::Map(_) => "kamus",
            Self::Function(_) | Self::Builtin(_) => "fungsi",
        }
    }
}

fn numbers(left: Value, right: Value, position: Position) -> Result<(f64, f64), RuntimeError> {
    fn number(value: Value) -> Option<f64> {
        match value {
            Value::Integer(value) => Some(value as f64),
            Value::Float(value) => Some(value),
            _ => None,
        }
    }
    let left = number(left).ok_or_else(|| RuntimeError {
        message: "operator membutuhkan dua bilangan".into(),
        position,
    })?;
    let right = number(right).ok_or_else(|| RuntimeError {
        message: "operator membutuhkan dua bilangan".into(),
        position,
    })?;
    Ok((left, right))
}

fn compare(
    left: &Value,
    right: &Value,
    position: Position,
) -> Result<std::cmp::Ordering, RuntimeError> {
    match (left, right) {
        (Value::String(a), Value::String(b)) => Some(a.cmp(b)),
        (Value::Integer(a), Value::Integer(b)) => Some(a.cmp(b)),
        (Value::Integer(a), Value::Float(b)) => (*a as f64).partial_cmp(b),
        (Value::Float(a), Value::Integer(b)) => a.partial_cmp(&(*b as f64)),
        (Value::Float(a), Value::Float(b)) => a.partial_cmp(b),
        _ => {
            return Err(RuntimeError {
                message: "nilai tidak dapat dibandingkan".into(),
                position,
            })
        }
    }
    .ok_or_else(|| RuntimeError {
        message: "nilai desimal tidak dapat dibandingkan".into(),
        position,
    })
}

fn normalize_index(index: i64, length: usize) -> Option<usize> {
    let length = i64::try_from(length).ok()?;
    let index = if index < 0 {
        length.checked_add(index)?
    } else {
        index
    };
    usize::try_from(index)
        .ok()
        .filter(|index| *index < length as usize)
}

fn one_arg(args: &[Value], position: Position, name: &str) -> Result<(), RuntimeError> {
    if args.len() == 1 {
        Ok(())
    } else {
        Err(RuntimeError {
            message: format!(
                "{name} membutuhkan tepat satu argumen, menerima {}",
                args.len()
            ),
            position,
        })
    }
}
