use crate::lexer::{Position, Token, TokenKind};
use std::fmt;

#[derive(Clone, Debug)]
pub struct Program(pub Vec<Stmt>);

#[derive(Clone, Debug)]
pub struct Stmt {
    pub kind: StmtKind,
    pub position: Position,
}

#[derive(Clone, Debug)]
pub enum StmtKind {
    Let(String, Expr),
    Assign(String, Expr),
    Expression(Expr),
    If {
        branches: Vec<(Expr, Vec<Stmt>)>,
        otherwise: Vec<Stmt>,
    },
    While {
        condition: Expr,
        body: Vec<Stmt>,
    },
    For {
        name: String,
        start: Expr,
        end: Expr,
        step: Option<Expr>,
        body: Vec<Stmt>,
    },
    Function {
        name: String,
        parameters: Vec<String>,
        body: Vec<Stmt>,
    },
    Return(Option<Expr>),
}

#[derive(Clone, Debug)]
pub struct Expr {
    pub kind: ExprKind,
    pub position: Position,
}

#[derive(Clone, Debug)]
pub enum ExprKind {
    Integer(i64),
    Float(f64),
    String(String),
    Bool(bool),
    Null,
    Variable(String),
    List(Vec<Expr>),
    Map(Vec<(Expr, Expr)>),
    Unary(UnaryOp, Box<Expr>),
    Binary(Box<Expr>, BinaryOp, Box<Expr>),
    Call(Box<Expr>, Vec<Expr>),
    Index(Box<Expr>, Box<Expr>),
}

#[derive(Clone, Copy, Debug)]
pub enum UnaryOp {
    Negate,
    Not,
}

#[derive(Clone, Copy, Debug)]
pub enum BinaryOp {
    Add,
    Subtract,
    Multiply,
    Divide,
    IntegerDivide,
    Remainder,
    Power,
    Equal,
    NotEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    And,
    Or,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ParseError {
    pub message: String,
    pub position: Position,
    pub incomplete: bool,
}

impl fmt::Display for ParseError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.message, self.position)
    }
}

impl std::error::Error for ParseError {}

pub fn parse(tokens: Vec<Token>) -> Result<Program, ParseError> {
    Parser { tokens, current: 0 }.program()
}

struct Parser {
    tokens: Vec<Token>,
    current: usize,
}

impl Parser {
    fn program(mut self) -> Result<Program, ParseError> {
        let mut statements = Vec::new();
        self.separators();
        while !self.at(&TokenKind::Eof) {
            statements.push(self.statement()?);
            self.require_separator()?;
        }
        Ok(Program(statements))
    }

    fn statement(&mut self) -> Result<Stmt, ParseError> {
        let position = self.peek().position;
        let kind = if self.take(&TokenKind::Let) {
            self.let_statement()?
        } else if self.take(&TokenKind::If) {
            self.if_statement()?
        } else if self.take(&TokenKind::While) {
            self.while_statement()?
        } else if self.take(&TokenKind::For) {
            self.for_statement()?
        } else if self.take(&TokenKind::Function) {
            self.function_statement()?
        } else if self.take(&TokenKind::Return) {
            self.return_statement()?
        } else if matches!(&self.peek().kind, TokenKind::Identifier(_))
            && matches!(self.next_kind(), Some(TokenKind::Assign))
        {
            self.assignment_statement()?
        } else {
            StmtKind::Expression(self.expression()?)
        };
        Ok(Stmt { kind, position })
    }

    fn let_statement(&mut self) -> Result<StmtKind, ParseError> {
        let name = self.identifier("nama variabel diharapkan setelah deklarasi")?;
        if !(self.take(&TokenKind::Assign) || self.take(&TokenKind::Equal)) {
            return Err(self.expected("'<-' atau '=' setelah nama variabel"));
        }
        Ok(StmtKind::Let(name, self.expression()?))
    }

    fn assignment_statement(&mut self) -> Result<StmtKind, ParseError> {
        let name = self.identifier("nama variabel diharapkan")?;
        self.advance();
        Ok(StmtKind::Assign(name, self.expression()?))
    }

    fn if_statement(&mut self) -> Result<StmtKind, ParseError> {
        let condition = self.expression()?;
        self.take(&TokenKind::Do);
        self.block_start()?;
        let body = self.block_until(&[TokenKind::ElseIf, TokenKind::Else, TokenKind::EndIf])?;
        let mut branches = vec![(condition, body)];
        while self.take(&TokenKind::ElseIf) {
            let condition = self.expression()?;
            self.take(&TokenKind::Do);
            self.block_start()?;
            let body = self.block_until(&[TokenKind::ElseIf, TokenKind::Else, TokenKind::EndIf])?;
            branches.push((condition, body));
        }
        let otherwise = if self.take(&TokenKind::Else) {
            self.block_start()?;
            self.block_until(&[TokenKind::EndIf])?
        } else {
            Vec::new()
        };
        self.consume(
            &TokenKind::EndIf,
            "'akhir_jika/end_if' untuk menutup percabangan",
        )?;
        Ok(StmtKind::If {
            branches,
            otherwise,
        })
    }

    fn while_statement(&mut self) -> Result<StmtKind, ParseError> {
        let condition = self.expression()?;
        self.take(&TokenKind::Do);
        self.block_start()?;
        let body = self.block_until(&[TokenKind::EndWhile])?;
        self.consume(
            &TokenKind::EndWhile,
            "'akhir_selama/end_while' untuk menutup perulangan",
        )?;
        Ok(StmtKind::While { condition, body })
    }

    fn for_statement(&mut self) -> Result<StmtKind, ParseError> {
        let name = self.identifier("nama variabel perulangan diharapkan")?;
        self.consume(&TokenKind::From, "'dari/from' setelah nama perulangan")?;
        let start = self.expression()?;
        self.consume(&TokenKind::To, "'sampai/to' setelah nilai awal")?;
        let end = self.expression()?;
        let step = if self.take(&TokenKind::Step) {
            Some(self.expression()?)
        } else {
            None
        };
        self.take(&TokenKind::Do);
        self.block_start()?;
        let body = self.block_until(&[TokenKind::EndFor])?;
        self.consume(
            &TokenKind::EndFor,
            "'akhir_untuk/end_for' untuk menutup perulangan",
        )?;
        Ok(StmtKind::For {
            name,
            start,
            end,
            step,
            body,
        })
    }

    fn function_statement(&mut self) -> Result<StmtKind, ParseError> {
        let name = self.identifier("nama fungsi diharapkan")?;
        self.consume(&TokenKind::LeftParen, "'(' setelah nama fungsi")?;
        let mut parameters = Vec::new();
        if !self.at(&TokenKind::RightParen) {
            loop {
                parameters.push(self.identifier("nama parameter diharapkan")?);
                if !self.take(&TokenKind::Comma) {
                    break;
                }
            }
        }
        self.consume(&TokenKind::RightParen, "')' setelah parameter")?;
        self.take(&TokenKind::Do);
        self.block_start()?;
        let body = self.block_until(&[TokenKind::EndFunction])?;
        self.consume(
            &TokenKind::EndFunction,
            "'akhir_fungsi/end_function' untuk menutup fungsi",
        )?;
        Ok(StmtKind::Function {
            name,
            parameters,
            body,
        })
    }

    fn return_statement(&mut self) -> Result<StmtKind, ParseError> {
        if self.at_separator() || self.at(&TokenKind::Eof) {
            Ok(StmtKind::Return(None))
        } else {
            Ok(StmtKind::Return(Some(self.expression()?)))
        }
    }

    fn block_start(&mut self) -> Result<(), ParseError> {
        if !self.at_separator() {
            return Err(self.expected("baris baru atau ';' sebelum isi blok"));
        }
        self.separators();
        Ok(())
    }

    fn block_until(&mut self, terminators: &[TokenKind]) -> Result<Vec<Stmt>, ParseError> {
        let mut body = Vec::new();
        while !terminators.iter().any(|kind| self.at(kind)) {
            if self.at(&TokenKind::Eof) {
                return Err(ParseError {
                    message: "blok belum ditutup sebelum akhir berkas".into(),
                    position: self.peek().position,
                    incomplete: true,
                });
            }
            body.push(self.statement()?);
            self.require_separator()?;
        }
        Ok(body)
    }

    fn expression(&mut self) -> Result<Expr, ParseError> {
        self.or()
    }

    fn or(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.and()?;
        while self.take(&TokenKind::Or) {
            let position = expr.position;
            expr = Expr {
                kind: ExprKind::Binary(Box::new(expr), BinaryOp::Or, Box::new(self.and()?)),
                position,
            };
        }
        Ok(expr)
    }

    fn and(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.equality()?;
        while self.take(&TokenKind::And) {
            let position = expr.position;
            expr = Expr {
                kind: ExprKind::Binary(Box::new(expr), BinaryOp::And, Box::new(self.equality()?)),
                position,
            };
        }
        Ok(expr)
    }

    fn equality(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.comparison()?;
        loop {
            let op = if self.take(&TokenKind::Equal) {
                Some(BinaryOp::Equal)
            } else if self.take(&TokenKind::NotEqual) {
                Some(BinaryOp::NotEqual)
            } else {
                None
            };
            let Some(op) = op else { break };
            let position = expr.position;
            expr = Expr {
                kind: ExprKind::Binary(Box::new(expr), op, Box::new(self.comparison()?)),
                position,
            };
        }
        Ok(expr)
    }

    fn comparison(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.term()?;
        loop {
            let op = if self.take(&TokenKind::Less) {
                Some(BinaryOp::Less)
            } else if self.take(&TokenKind::LessEqual) {
                Some(BinaryOp::LessEqual)
            } else if self.take(&TokenKind::Greater) {
                Some(BinaryOp::Greater)
            } else if self.take(&TokenKind::GreaterEqual) {
                Some(BinaryOp::GreaterEqual)
            } else {
                None
            };
            let Some(op) = op else { break };
            let position = expr.position;
            expr = Expr {
                kind: ExprKind::Binary(Box::new(expr), op, Box::new(self.term()?)),
                position,
            };
        }
        Ok(expr)
    }

    fn term(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.factor()?;
        loop {
            let op = if self.take(&TokenKind::Plus) {
                Some(BinaryOp::Add)
            } else if self.take(&TokenKind::Minus) {
                Some(BinaryOp::Subtract)
            } else {
                None
            };
            let Some(op) = op else { break };
            let position = expr.position;
            expr = Expr {
                kind: ExprKind::Binary(Box::new(expr), op, Box::new(self.factor()?)),
                position,
            };
        }
        Ok(expr)
    }

    fn factor(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.power()?;
        loop {
            let op = if self.take(&TokenKind::Star) {
                Some(BinaryOp::Multiply)
            } else if self.take(&TokenKind::Slash) {
                Some(BinaryOp::Divide)
            } else if self.take(&TokenKind::SlashSlash) {
                Some(BinaryOp::IntegerDivide)
            } else if self.take(&TokenKind::Percent) {
                Some(BinaryOp::Remainder)
            } else {
                None
            };
            let Some(op) = op else { break };
            let position = expr.position;
            expr = Expr {
                kind: ExprKind::Binary(Box::new(expr), op, Box::new(self.power()?)),
                position,
            };
        }
        Ok(expr)
    }

    fn power(&mut self) -> Result<Expr, ParseError> {
        let expr = self.unary()?;
        if self.take(&TokenKind::Power) {
            let position = expr.position;
            Ok(Expr {
                kind: ExprKind::Binary(Box::new(expr), BinaryOp::Power, Box::new(self.power()?)),
                position,
            })
        } else {
            Ok(expr)
        }
    }

    fn unary(&mut self) -> Result<Expr, ParseError> {
        let position = self.peek().position;
        if self.take(&TokenKind::Minus) {
            Ok(Expr {
                kind: ExprKind::Unary(UnaryOp::Negate, Box::new(self.unary()?)),
                position,
            })
        } else if self.take(&TokenKind::Not) {
            Ok(Expr {
                kind: ExprKind::Unary(UnaryOp::Not, Box::new(self.unary()?)),
                position,
            })
        } else {
            self.postfix()
        }
    }

    fn postfix(&mut self) -> Result<Expr, ParseError> {
        let mut expr = self.primary()?;
        loop {
            if self.take(&TokenKind::LeftParen) {
                let mut args = Vec::new();
                self.newlines();
                if !self.at(&TokenKind::RightParen) {
                    loop {
                        args.push(self.expression()?);
                        self.newlines();
                        if !self.take(&TokenKind::Comma) {
                            break;
                        }
                        self.newlines();
                        if self.at(&TokenKind::RightParen) {
                            break;
                        }
                    }
                }
                self.consume(&TokenKind::RightParen, "')' setelah argumen")?;
                let position = expr.position;
                expr = Expr {
                    kind: ExprKind::Call(Box::new(expr), args),
                    position,
                };
            } else if self.take(&TokenKind::LeftBracket) {
                self.newlines();
                let index = self.expression()?;
                self.newlines();
                self.consume(&TokenKind::RightBracket, "']' setelah indeks")?;
                let position = expr.position;
                expr = Expr {
                    kind: ExprKind::Index(Box::new(expr), Box::new(index)),
                    position,
                };
            } else {
                break;
            }
        }
        Ok(expr)
    }

    fn primary(&mut self) -> Result<Expr, ParseError> {
        let token = self.advance().clone();
        let kind = match token.kind {
            TokenKind::Integer(value) => ExprKind::Integer(value),
            TokenKind::Float(value) => ExprKind::Float(value),
            TokenKind::String(value) => ExprKind::String(value),
            TokenKind::True => ExprKind::Bool(true),
            TokenKind::False => ExprKind::Bool(false),
            TokenKind::Null => ExprKind::Null,
            TokenKind::Identifier(name) => ExprKind::Variable(name),
            TokenKind::LeftParen => {
                self.newlines();
                let expr = self.expression()?;
                self.newlines();
                self.consume(&TokenKind::RightParen, "')' setelah ekspresi")?;
                return Ok(expr);
            }
            TokenKind::LeftBracket => return self.list(token.position),
            TokenKind::LeftBrace => return self.map(token.position),
            TokenKind::Eof => {
                return Err(ParseError {
                    message: "ekspresi diharapkan sebelum akhir berkas".into(),
                    position: token.position,
                    incomplete: true,
                })
            }
            other => {
                return Err(ParseError {
                    message: format!("ekspresi diharapkan, ditemukan {}", other.name()),
                    position: token.position,
                    incomplete: false,
                })
            }
        };
        Ok(Expr {
            kind,
            position: token.position,
        })
    }

    fn list(&mut self, position: Position) -> Result<Expr, ParseError> {
        let mut values = Vec::new();
        self.newlines();
        if !self.at(&TokenKind::RightBracket) {
            loop {
                values.push(self.expression()?);
                self.newlines();
                if !self.take(&TokenKind::Comma) {
                    break;
                }
                self.newlines();
                if self.at(&TokenKind::RightBracket) {
                    break;
                }
            }
        }
        self.consume(&TokenKind::RightBracket, "']' untuk menutup daftar")?;
        Ok(Expr {
            kind: ExprKind::List(values),
            position,
        })
    }

    fn map(&mut self, position: Position) -> Result<Expr, ParseError> {
        let mut entries = Vec::new();
        self.newlines();
        if !self.at(&TokenKind::RightBrace) {
            loop {
                let key = self.expression()?;
                self.consume(&TokenKind::Colon, "':' setelah kunci kamus")?;
                self.newlines();
                entries.push((key, self.expression()?));
                self.newlines();
                if !self.take(&TokenKind::Comma) {
                    break;
                }
                self.newlines();
                if self.at(&TokenKind::RightBrace) {
                    break;
                }
            }
        }
        self.consume(&TokenKind::RightBrace, "'}' untuk menutup kamus")?;
        Ok(Expr {
            kind: ExprKind::Map(entries),
            position,
        })
    }

    fn require_separator(&mut self) -> Result<(), ParseError> {
        if self.at_separator() {
            self.separators();
            Ok(())
        } else if self.at(&TokenKind::Eof) {
            Ok(())
        } else {
            Err(self.expected("baris baru atau ';' di antara pernyataan"))
        }
    }

    fn separators(&mut self) {
        while self.at_separator() {
            self.current += 1;
        }
    }
    fn newlines(&mut self) {
        while self.at(&TokenKind::Newline) {
            self.current += 1;
        }
    }
    fn at_separator(&self) -> bool {
        self.at(&TokenKind::Newline) || self.at(&TokenKind::Semicolon)
    }
    fn identifier(&mut self, message: &str) -> Result<String, ParseError> {
        let token = self.advance().clone();
        if let TokenKind::Identifier(name) = token.kind {
            Ok(name)
        } else {
            Err(ParseError {
                message: message.into(),
                position: token.position,
                incomplete: matches!(token.kind, TokenKind::Eof),
            })
        }
    }
    fn consume(&mut self, kind: &TokenKind, expected: &str) -> Result<(), ParseError> {
        if self.take(kind) {
            Ok(())
        } else {
            Err(self.expected(expected))
        }
    }
    fn expected(&self, expected: &str) -> ParseError {
        ParseError {
            message: format!(
                "diharapkan {expected}, ditemukan {}",
                self.peek().kind.name()
            ),
            position: self.peek().position,
            incomplete: self.at(&TokenKind::Eof),
        }
    }
    fn take(&mut self, kind: &TokenKind) -> bool {
        if self.at(kind) {
            self.current += 1;
            true
        } else {
            false
        }
    }
    fn at(&self, kind: &TokenKind) -> bool {
        std::mem::discriminant(&self.peek().kind) == std::mem::discriminant(kind)
    }
    fn peek(&self) -> &Token {
        &self.tokens[self.current]
    }
    fn next_kind(&self) -> Option<&TokenKind> {
        self.tokens.get(self.current + 1).map(|token| &token.kind)
    }
    fn advance(&mut self) -> &Token {
        let index = self.current;
        if !self.at(&TokenKind::Eof) {
            self.current += 1;
        }
        &self.tokens[index]
    }
}
