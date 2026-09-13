use std::fmt;

#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub struct Position {
    pub line: usize,
    pub column: usize,
}

impl fmt::Display for Position {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "baris {}, kolom {}", self.line, self.column)
    }
}

#[derive(Clone, Debug, PartialEq)]
pub enum TokenKind {
    Integer(i64),
    Float(f64),
    String(String),
    Identifier(String),
    Let,
    If,
    Do,
    ElseIf,
    Else,
    EndIf,
    While,
    EndWhile,
    For,
    From,
    To,
    Step,
    EndFor,
    Function,
    EndFunction,
    Return,
    True,
    False,
    Null,
    And,
    Or,
    Not,
    Plus,
    Minus,
    Star,
    Slash,
    SlashSlash,
    Percent,
    Power,
    Equal,
    NotEqual,
    Less,
    LessEqual,
    Greater,
    GreaterEqual,
    Assign,
    LeftParen,
    RightParen,
    LeftBracket,
    RightBracket,
    LeftBrace,
    RightBrace,
    Comma,
    Colon,
    Newline,
    Semicolon,
    Eof,
}

impl TokenKind {
    pub(crate) fn name(&self) -> &'static str {
        match self {
            Self::Integer(_) => "bilangan bulat",
            Self::Float(_) => "bilangan desimal",
            Self::String(_) => "teks",
            Self::Identifier(_) => "nama",
            Self::Let => "ubah/var/let",
            Self::If => "jika/if",
            Self::Do => "maka/do",
            Self::ElseIf => "atau_jika/else_if",
            Self::Else => "selain/else",
            Self::EndIf => "akhir_jika/end_if",
            Self::While => "selama/while",
            Self::EndWhile => "akhir_selama/end_while",
            Self::For => "untuk/for",
            Self::From => "dari/from",
            Self::To => "sampai/to",
            Self::Step => "langkah/step",
            Self::EndFor => "akhir_untuk/end_for",
            Self::Function => "fungsi/function",
            Self::EndFunction => "akhir_fungsi/end_function",
            Self::Return => "kembalikan/return",
            Self::True => "benar/true",
            Self::False => "salah/false",
            Self::Null => "kosong/null",
            Self::And => "dan/and",
            Self::Or => "atau/or",
            Self::Not => "tidak/not",
            Self::Plus => "+",
            Self::Minus => "-",
            Self::Star => "*",
            Self::Slash => "/",
            Self::SlashSlash => "//",
            Self::Percent => "%",
            Self::Power => "**",
            Self::Equal => "=",
            Self::NotEqual => "!=",
            Self::Less => "<",
            Self::LessEqual => "<=",
            Self::Greater => ">",
            Self::GreaterEqual => ">=",
            Self::Assign => "<-",
            Self::LeftParen => "(",
            Self::RightParen => ")",
            Self::LeftBracket => "[",
            Self::RightBracket => "]",
            Self::LeftBrace => "{",
            Self::RightBrace => "}",
            Self::Comma => ",",
            Self::Colon => ":",
            Self::Newline => "baris baru",
            Self::Semicolon => ";",
            Self::Eof => "akhir berkas",
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct Token {
    pub kind: TokenKind,
    pub position: Position,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LexError {
    pub message: String,
    pub position: Position,
}

impl fmt::Display for LexError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{} ({})", self.message, self.position)
    }
}

impl std::error::Error for LexError {}

pub fn lex(source: &str) -> Result<Vec<Token>, LexError> {
    Lexer::new(source).scan()
}

struct Lexer {
    chars: Vec<char>,
    current: usize,
    line: usize,
    column: usize,
}

impl Lexer {
    fn new(source: &str) -> Self {
        Self {
            chars: source.chars().collect(),
            current: 0,
            line: 1,
            column: 1,
        }
    }

    fn scan(mut self) -> Result<Vec<Token>, LexError> {
        let mut tokens = Vec::new();
        while let Some(ch) = self.peek() {
            let position = self.position();
            match ch {
                ' ' | '\t' | '\r' => self.advance(),
                '\n' => {
                    self.advance();
                    tokens.push(Token {
                        kind: TokenKind::Newline,
                        position,
                    });
                }
                '#' => {
                    while !matches!(self.peek(), Some('\n') | None) {
                        self.advance();
                    }
                }
                '0'..='9' => tokens.push(Token {
                    kind: self.number(position)?,
                    position,
                }),
                '"' | '\'' => tokens.push(Token {
                    kind: self.string(ch, position)?,
                    position,
                }),
                c if is_identifier_start(c) => tokens.push(Token {
                    kind: self.identifier(),
                    position,
                }),
                '+' => {
                    self.advance();
                    tokens.push(Token {
                        kind: TokenKind::Plus,
                        position,
                    });
                }
                '-' => {
                    self.advance();
                    tokens.push(Token {
                        kind: TokenKind::Minus,
                        position,
                    });
                }
                '*' => {
                    self.advance();
                    let kind = if self.take('*') {
                        TokenKind::Power
                    } else {
                        TokenKind::Star
                    };
                    tokens.push(Token { kind, position });
                }
                '/' => {
                    self.advance();
                    let kind = if self.take('/') {
                        TokenKind::SlashSlash
                    } else {
                        TokenKind::Slash
                    };
                    tokens.push(Token { kind, position });
                }
                '%' => {
                    self.advance();
                    tokens.push(Token {
                        kind: TokenKind::Percent,
                        position,
                    });
                }
                '=' => {
                    self.advance();
                    self.take('=');
                    tokens.push(Token {
                        kind: TokenKind::Equal,
                        position,
                    });
                }
                '!' => {
                    self.advance();
                    if self.take('=') {
                        tokens.push(Token {
                            kind: TokenKind::NotEqual,
                            position,
                        });
                    } else {
                        return Err(self.error("'!' harus diikuti '='", position));
                    }
                }
                '<' => {
                    self.advance();
                    let kind = if self.take('-') {
                        TokenKind::Assign
                    } else if self.take('=') {
                        TokenKind::LessEqual
                    } else {
                        TokenKind::Less
                    };
                    tokens.push(Token { kind, position });
                }
                '>' => {
                    self.advance();
                    let kind = if self.take('=') {
                        TokenKind::GreaterEqual
                    } else {
                        TokenKind::Greater
                    };
                    tokens.push(Token { kind, position });
                }
                '(' => self.single(&mut tokens, TokenKind::LeftParen, position),
                ')' => self.single(&mut tokens, TokenKind::RightParen, position),
                '[' => self.single(&mut tokens, TokenKind::LeftBracket, position),
                ']' => self.single(&mut tokens, TokenKind::RightBracket, position),
                '{' => self.single(&mut tokens, TokenKind::LeftBrace, position),
                '}' => self.single(&mut tokens, TokenKind::RightBrace, position),
                ',' => self.single(&mut tokens, TokenKind::Comma, position),
                ':' => self.single(&mut tokens, TokenKind::Colon, position),
                ';' => self.single(&mut tokens, TokenKind::Semicolon, position),
                _ => return Err(self.error(format!("karakter tidak dikenal '{ch}'"), position)),
            }
        }
        tokens.push(Token {
            kind: TokenKind::Eof,
            position: self.position(),
        });
        Ok(tokens)
    }

    fn single(&mut self, tokens: &mut Vec<Token>, kind: TokenKind, position: Position) {
        self.advance();
        tokens.push(Token { kind, position });
    }

    fn number(&mut self, position: Position) -> Result<TokenKind, LexError> {
        let start = self.current;
        while matches!(self.peek(), Some('0'..='9')) {
            self.advance();
        }
        let mut float = false;
        if self.peek() == Some('.') && matches!(self.peek_next(), Some('0'..='9')) {
            float = true;
            self.advance();
            while matches!(self.peek(), Some('0'..='9')) {
                self.advance();
            }
        }
        let text: String = self.chars[start..self.current].iter().collect();
        if float {
            text.parse::<f64>()
                .map(TokenKind::Float)
                .map_err(|_| self.error("bilangan desimal tidak sah", position))
        } else {
            text.parse::<i64>()
                .map(TokenKind::Integer)
                .map_err(|_| self.error("bilangan bulat berada di luar jangkauan", position))
        }
    }

    fn string(&mut self, quote: char, position: Position) -> Result<TokenKind, LexError> {
        self.advance();
        let mut value = String::new();
        while let Some(ch) = self.peek() {
            if ch == quote {
                self.advance();
                return Ok(TokenKind::String(value));
            }
            if ch == '\n' {
                return Err(self.error("teks belum ditutup sebelum akhir baris", position));
            }
            self.advance();
            if ch == '\\' {
                let escaped = self
                    .peek()
                    .ok_or_else(|| self.error("escape teks tidak lengkap", position))?;
                self.advance();
                value.push(match escaped {
                    'n' => '\n',
                    't' => '\t',
                    'r' => '\r',
                    '\\' => '\\',
                    '"' => '"',
                    '\'' => '\'',
                    other => {
                        return Err(self
                            .error(format!("escape '\\{other}' tidak dikenal"), self.position()))
                    }
                });
            } else {
                value.push(ch);
            }
        }
        Err(self.error("teks belum ditutup", position))
    }

    fn identifier(&mut self) -> TokenKind {
        let start = self.current;
        while matches!(self.peek(), Some(c) if is_identifier_continue(c)) {
            self.advance();
        }
        let text: String = self.chars[start..self.current].iter().collect();
        keyword(&text).unwrap_or(TokenKind::Identifier(text))
    }

    fn peek(&self) -> Option<char> {
        self.chars.get(self.current).copied()
    }
    fn peek_next(&self) -> Option<char> {
        self.chars.get(self.current + 1).copied()
    }
    fn take(&mut self, expected: char) -> bool {
        if self.peek() == Some(expected) {
            self.advance();
            true
        } else {
            false
        }
    }
    fn advance(&mut self) {
        if let Some(ch) = self.peek() {
            self.current += 1;
            if ch == '\n' {
                self.line += 1;
                self.column = 1;
            } else {
                self.column += 1;
            }
        }
    }
    fn position(&self) -> Position {
        Position {
            line: self.line,
            column: self.column,
        }
    }
    fn error(&self, message: impl Into<String>, position: Position) -> LexError {
        LexError {
            message: message.into(),
            position,
        }
    }
}

fn is_identifier_start(ch: char) -> bool {
    ch == '_' || ch.is_alphabetic()
}
fn is_identifier_continue(ch: char) -> bool {
    ch == '_' || ch.is_alphanumeric()
}

fn keyword(text: &str) -> Option<TokenKind> {
    Some(match text {
        "ubah" | "let" | "var" => TokenKind::Let,
        "jika" | "if" => TokenKind::If,
        "maka" | "do" => TokenKind::Do,
        "atau_jika" | "else_if" => TokenKind::ElseIf,
        "selain" | "else" => TokenKind::Else,
        "akhir_jika" | "end_if" => TokenKind::EndIf,
        "selama" | "while" => TokenKind::While,
        "akhir_selama" | "end_while" => TokenKind::EndWhile,
        "untuk" | "for" => TokenKind::For,
        "dari" | "from" => TokenKind::From,
        "sampai" | "to" => TokenKind::To,
        "langkah" | "step" => TokenKind::Step,
        "akhir_untuk" | "end_for" => TokenKind::EndFor,
        "fungsi" | "function" => TokenKind::Function,
        "akhir_fungsi" | "end_function" => TokenKind::EndFunction,
        "kembalikan" | "return" => TokenKind::Return,
        "benar" | "true" => TokenKind::True,
        "salah" | "false" => TokenKind::False,
        "kosong" | "null" => TokenKind::Null,
        "dan" | "and" => TokenKind::And,
        "atau" | "or" => TokenKind::Or,
        "tidak" | "not" => TokenKind::Not,
        _ => return None,
    })
}
