/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module lex;

import std.ascii;
import std.c.stdlib;
import std.container;
import std.conv;
import std.stdio;
import std.string;


/**
 * String table of reserved keywords
 */
const string[] keywords = [
	"auto", "break", "case", "char", "const", "continue", "default", "do",
	"double", "else", "enum", "extern", "float", "for", "goto", "if", "int",
	"long", "register", "return", "short", "signed","sizeof", "static",
	"struct", "switch", "typedef", "union", "unsigned", "void", "volatile",
	"while"
];

/**
 * Represents an individual token.
 */
enum Token : ushort {
	IDENTIFIER, KEYWORD,
	LITERAL_STR, LITERAL_CHAR, LITERAL_INT, LITERAL_FLOAT,
	SEMICOLON,
	COMMA,
	DOT, ARROW,
	BRACE_OPEN, BRACE_CLOSE,
	PAREN_OPEN, PAREN_CLOSE,
	BRACKET_OPEN, BRACKET_CLOSE,
	ADD, SUBTRACT, MULTIPLY, DIVIDE, MODULO,
	NOT, AND, OR, XOR,
	BANG, SS_AND, SS_OR,
	ASSIGN,
	ASSIGN_ADD, ASSIGN_SUBTRACT, ASSIGN_MULTIPLY, ASSIGN_DIVIDE, ASSIGN_MODULO,
	EOF,
}

/**
 * Combines a Token enum with a string tag (for identifiers, keywords, etc.).
 */
struct TokenTag {
	Token token;
	ulong line, col;
	string tag;
	
	/**
	 * Initializes the class with token and line, optionally col, and no tag.
	 */
	this(Token token, ulong line, ulong col = 0) {
		this.token = token;
		this.line = line;
		this.col = col;
	}
}

/**
 * Represents the current state of the lexer.
 */
enum LexState : ushort {
	DEFAULT,
	COMMENT_BLOCK, COMMENT_LINE,
	IDENTIFIER,
	LITERAL_STR, LITERAL_CHAR,
	LITERAL_INT_D, LITERAL_INT_O, LITERAL_INT_H, LITERAL_FLOAT,
}

/**
 * Contains the lexer's state and the list of processed tokens.
 */
struct LexContext {
	DList!TokenTag tokens;
	LexState state;
	ulong line, col;
	
	/+@property LexState state() {
		return actualState;
	}
	@property LexState state(LexState newState) {
		writef("state: %s\n", newState);
		return (actualState = newState);
	}
	LexState actualState;+/
	
	this(ulong line = 1, ulong col = 1) {
		this.line = line;
		this.col = col;
	}
}

/**
 * Indicates that the lexer has attempted to read or advance past the end of the
 * file.
 */
class LexOverrunException : Exception {
	this() {
		super("");
	}
}


/**
 * Lexes the contents of inputFile.
 * 
 * Params:
 * source =
 *  a string containing the source code to be lexed
 * Returns: a LexContext struct containing the list of tokens found in the file
 */
LexContext lexSource(string source) {
	auto ctx = LexContext(1, 1);
	string cur = source;
	char[] buffer = new char[0];
	ulong startCol = 0;
	
	/*
	 * Adds a token to the list in ctx with the current line and column.
	 */
	void addToken(Token token) {
		ctx.tokens.insertBack(TokenTag(token, ctx.line, ctx.col));
	}
	
	/**
	 * Advances the cursor by the requested number of places.
	 */
	void advance(ulong count = 1) {
		cur = cur[count..$];
		ctx.col += count;
	}
	
	/*
	 * Checks whether the cursor is at a newline.
	 */
	bool atNewLine() {
		return (cur[0] == '\n' || cur[0] == '\r');
	}
	
	/**
	 * Handles weird line endings and adjusts the context for newlines.
	 */
	void handleNewLine() {
		/* deal with \r\n and \n\r line endings */
		if (cur.length > 1) {
			if ((cur[0] == '\n' && cur[1] == '\r') ||
				(cur[0] == '\r' && cur[1] == '\n')) {
				advance();
			}
		}
		
		/* col is set to zero because advance will get called after this */
		++ctx.line;
		ctx.col = 0;
	}
	
	/*
	 * Checks if an integer literal has been completed and, if so, adds it as a
	 * token.
	 */
	void finishInteger() {
		string decPattern = "0-9";
		string octPattern = "0-7";
		string hexPattern = "0-9A-Fa-f";
		
		// check ctx.state to determine if we are dec, oct, or hex
		
		// if we are in dec mode and we run across a '.', switch the mode to
		// float mode and call finishFloat
	}
	
	/**
	 * Checks if an identifier has been completed and, if so, adds it as a
	 * token.
	 */
	void finishIdentifier() {
		if (cur.length == 1 || !inPattern(cur[1], "A-Za-z0-9_")) {
			string identifier = to!string(buffer);
			bool isKeyword = false;
			
			foreach (keyword; keywords) {
				if (identifier == keyword) {
					isKeyword = true;
					break;
				}
			}
			
			auto token = TokenTag((isKeyword ? Token.KEYWORD :
				Token.IDENTIFIER), ctx.line, startCol);
			token.tag = identifier;
			ctx.tokens.insertBack(token);
			
			buffer.length = 0;
			ctx.state = LexState.DEFAULT;
		}
	}
	
	/*
	 * Appends the _escape sequence represented by escape to the buffer.
	 */
	void appendEscapeChar(in char escape) {
		/* TODO: implement hex/octal escape sequences */
		
		if (escape == '\'' || escape == '"' ||
			escape == '?' || escape == '\\') {
			buffer ~= escape;
		} else if (escape == 'a') {
			buffer ~= '\a';
		} else if (escape == 'b') {
			buffer ~= '\b';
		} else if (escape == 'f') {
			buffer ~= '\f';
		} else if (escape == 'r') {
			buffer ~= '\r';
		} else if (escape == 't') {
			buffer ~= '\t';
		} else if (escape == 'v') {
			buffer ~= '\v';
		} else {
			stderr.writef("[lex:%d] unknown escape sequence: '\\%c'\n",
				ctx.line, escape);
			exit(1);
		}
	}
	
	while (cur.length > 0) {
		/* NOTE! for multi-char tokens, peek ahead one character and, if it is
		 * not part of the token (i.e., no longer [A-Z]|[a-z]|_) then revert the
		 * state back to DEFAULT */
		
		/* based on the current state, read a token and/or change the state */
		if (ctx.state == LexState.DEFAULT) {
			if (atNewLine()) {
				handleNewLine();
			} else if (cur[0] == '.') {
				addToken(Token.DOT);
			} else if (cur[0] == '-') {
				if (cur.length >= 2 && cur[1] == '>') {
					addToken(Token.ARROW);
					advance();
				}
			} else if (cur[0] == '~') {
				addToken(Token.NOT);
			} else if (cur[0] == '!') {
				addToken(Token.BANG);
			} else if (cur[0] == '^') {
				addToken(Token.XOR);
			} else if (cur[0] == '&') {
				if (cur.length >= 2 && cur[1] == '&') {
					addToken(Token.SS_AND);
					advance();
				} else {
					addToken(Token.AND);
				}
			} else if (cur[0] == '|') {
				if (cur.length >= 2 && cur[1] == '|') {
					addToken(Token.SS_OR);
					advance();
				} else {
					addToken(Token.OR);
				}
			} else if (cur[0] == '+') {
				addToken(Token.ADD);
			} else if (cur[0] == '-') {
				addToken(Token.SUBTRACT);
			} else if (cur[0] == '*') {
				addToken(Token.MULTIPLY);
			} else if (cur[0] == '/') {
				if (cur.length >= 2 && cur[1] == '/') {
					advance();
					ctx.state = LexState.COMMENT_LINE;
				} else if (cur.length >= 2 && cur[1] == '*') {
					advance();
					ctx.state = LexState.COMMENT_BLOCK;
				} else {
					addToken(Token.DIVIDE);
				}
			} else if (cur[0] == '%') {
				addToken(Token.MODULO);
			} else if (cur[0] == ';') {
				addToken(Token.SEMICOLON);
			} else if (cur[0] == ',') {
				addToken(Token.COMMA);
			} else if (cur[0] == '{') {
				addToken(Token.BRACE_OPEN);
			} else if (cur[0] == '}') {
				addToken(Token.BRACE_CLOSE);
			} else if (cur[0] == '(') {
				addToken(Token.PAREN_OPEN);
			} else if (cur[0] == ')') {
				addToken(Token.PAREN_CLOSE);
			} else if (cur[0] == '[') {
				addToken(Token.BRACKET_OPEN);
			} else if (cur[0] == ']') {
				addToken(Token.BRACKET_CLOSE);
			} else if (cur[0] == '"') {
				startCol = ctx.col;
				ctx.state = LexState.LITERAL_STR;
			} else if (cur[0] == '\'') {
				startCol = ctx.col;
				ctx.state = LexState.LITERAL_CHAR;
			} else if (inPattern(cur[0], "0-9")) {
				startCol = ctx.col;
				buffer ~= cur[0];
				
				if (cur[0] == '0') {
					if (cur.length >= 2 && toLower(cur[1]) == 'x') {
						ctx.state = LexState.LITERAL_INT_H;
					} else {
						ctx.state = LexState.LITERAL_INT_O;
					}
				} else {
					ctx.state = LexState.LITERAL_INT_D;
				}
				
				finishInteger();
			} else if (inPattern(cur[0], "A-Za-z_")) {
				startCol = ctx.col;
				buffer ~= cur[0];
				finishIdentifier();
				
				ctx.state = LexState.IDENTIFIER;
			} else if (cur[0] == ' ' || cur[0] == '\t') {
				/* ignore whitespace */
			} else {
				stderr.writef("[lex:%d] unexpected character: '%c'\n", ctx.line,
					cur[0]);
				//exit(1);
			}
		} else if (ctx.state == LexState.COMMENT_BLOCK) {
			if (atNewLine()) {
				handleNewLine();
			} else if (cur[0] == '*') {
				if (cur.length >= 2 && cur[1] == '/') {
					advance();
					ctx.state = LexState.DEFAULT;
				}
			}
		} else if (ctx.state == LexState.COMMENT_LINE) {
			if (atNewLine()) {
				handleNewLine();
				ctx.state = LexState.DEFAULT;
			}
		} else if (ctx.state == LexState.LITERAL_STR ||
			ctx.state == LexState.LITERAL_CHAR) {
			if (cur[0] == '\\') {
				if (cur.length >= 2) {
					if (cur[1] == '\n' || cur[1] == '\r') {
						stderr.writef("[lex:%d] escape sequence interrupted " ~
							"by newline\n", ctx.line);
						exit(1);
					} else {
						appendEscapeChar(cur[1]);
						advance();
					}
				} else {
					stderr.writef("[lex:%d] found an incomplete escape " ~
						"sequence\n", ctx.line);
					exit(1);
				}
			} else if (ctx.state == LexState.LITERAL_STR && cur[0] == '"') {
				auto token = TokenTag(Token.LITERAL_STR, ctx.line, startCol);
				token.tag = to!string(buffer);
				ctx.tokens.insertBack(token);
				
				buffer.length = 0;
				ctx.state = LexState.DEFAULT;
			} else if (ctx.state == LexState.LITERAL_CHAR && cur[0] == '\'') {
				if (buffer.length == 0) {
					stderr.writef("[lex:%d] found an empty char literal\n",
						ctx.line);
					exit(1);
				} else if (buffer.length > 1) {
					stderr.writef("[lex:%d] found a char literal with too " ~
						"many chars\n", ctx.line);
					exit(1);
				}
				
				auto token = TokenTag(Token.LITERAL_CHAR, ctx.line, startCol);
				token.tag = to!string(buffer[0]);
				ctx.tokens.insertBack(token);
				
				buffer.length = 0;
				ctx.state = LexState.DEFAULT;
			} else if (cur[0] == '\n' || cur[0] == '\r') {
				stderr.writef("[lex:%d] encountered a newline within a " ~
					"%s literal\n", ctx.line, (ctx.state ==
					LexState.LITERAL_STR ? "string" : "char"));
				exit(1);
			} else {
				buffer ~= cur[0];
			}
		} else if (ctx.state == LexState.LITERAL_INT_D ||
			ctx.state == LexState.LITERAL_INT_O ||
			ctx.state == LexState.LITERAL_INT_H) {
			buffer ~= cur[0];
			
			finishInteger();
		} else if (ctx.state == LexState.IDENTIFIER) {
			buffer ~= cur[0];
			
			finishIdentifier();
		} else {
			
		}
		
		advance();
	}
	
	ctx.tokens.insertBack(TokenTag(Token.EOF, ctx.line));
	
	/* determine if the state in which we find ourselves after EOF is correct */
	if (ctx.state == LexState.COMMENT_BLOCK) {
		stderr.writef("[lex:%d] encountered EOF while still in a comment " ~
			"block\n", ctx.line);
		exit(1);
	} else if (ctx.state == LexState.LITERAL_STR) {
		stderr.writef("[lex:%d] encountered EOF while still in a string " ~
			"literal\n", ctx.line);
		exit(1);
	}
	
	write("[lex] tokens:\n");
	foreach (t; ctx.tokens) {
		writef("line%4d  col %2d:  %s%s\n", t.line, t.col, t.token,
			(t.tag != "" ? (" [" ~ t.tag ~ "]") : ""));
	}
	
	return ctx;
}
