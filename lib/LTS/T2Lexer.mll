{
  open T2Parser
  open Lexing

  exception SyntaxError of string

  let update_loc (lexbuf: Lexing.lexbuf) =
    let pos = lexbuf.lex_curr_p in
    lexbuf.lex_curr_p <- { pos with
      pos_lnum = pos.pos_lnum + 1;
      pos_bol = pos.pos_cnum;
    }
}

let space = ' ' | '\t'
let newline = '\r' | '\n' | "\r\n"
let digit = ['0'-'9']
let alpha = ['A'-'Z' 'a'-'z']
(*let operator = '+' | '-' | '*' | '/' | '%'
let comp = "==" | ">=" | '<' | "<=" | '<'*)

rule token = parse
| "START" { START }
| "ERROR" { ERROR }
| "FROM" { FROM }
| "TO" { TO }
| "AT" { AT }
| "CUTPOINT" { CUTPOINT }
| "SHADOW" { SHADOW }
| ':' { COLON }
| ';' { SEMICOLON }
| ',' { COMMA }
| "skip" { SKIP }
| "nondet" { NONDET }
| "assume" { ASSUME }
| digit+ { INT (Lexing.lexeme lexbuf |> int_of_string) }
| (alpha | '_') (digit | alpha | '_' | '.')* ('!' digit+)? { VAR (Lexing.lexeme lexbuf) }
| '"' [^'"']* '"' { STRING }
| ":=" { SUBST }
| '(' { LPAREN }
| ')' { RPAREN }
| space { token lexbuf }
| newline | "//" [^'\n']* newline { update_loc lexbuf; token lexbuf }

| '+' { PLUS }
| '-' { MINUS }
| '*' { TIMES }
| '/' { DIV }
| '%' { MOD }
| "==" { EQ }
| "!=" { NEQ }
| '>' { GT }
| '<' { LT }
| ">=" { GEQ }
| "<=" { LEQ }
| "&&" | "/\\" { AND }
| "||" | "\\/" { OR }
| "!" { NOT }

| eof {  EOF }
| _ { raise (SyntaxError ("Unexpected char: " ^ Lexing.lexeme lexbuf)) }
