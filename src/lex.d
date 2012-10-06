/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module lex;

import core.time;
import core.vararg;
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
 * Represents a token's type.
 */
enum TokenType : ubyte {
	IDENTIFIER, KEYWORD,
	LITERAL_INT, LITERAL_UINT, LITERAL_LONG, LITERAL_ULONG,
	LITERAL_FLOAT, LITERAL_DOUBLE,
	LITERAL_STR, LITERAL_CHAR,
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
	EQUAL, NOT_EQUAL,
	LESS, LESS_EQUAL,
	GREATER, GREATER_EQUAL,
	EOF,
}

/**
 * Combines a TokenType enum with a tag containing an identifier or literal.
 */
struct Token {
	TokenType type;
	ulong line, col;
	
	union {
		int tagInt;
		uint tagUInt;
		long tagLong;
		ulong tagULong;
		
		float tagFlt;
		double tagDbl;
		
		string tagStr;
	}
	
	/**
	 * Initializes the struct, optionally with a tag of appropriate type
	 */
	this(TokenType type, ulong line, ulong col, ...) {
		this.type = type;
		this.line = line;
		this.col = col;
		
		assert(_arguments.length <= 1);
		
		foreach (arg; _arguments) {
			if (arg == typeid(int)) {
				tagInt = va_arg!int(_argptr);
				assert(type == TokenType.LITERAL_INT);
			} else if (arg == typeid(uint)) {
				tagUInt = va_arg!uint(_argptr);
				assert(type == TokenType.LITERAL_UINT);
			} else if (arg == typeid(long)) {
				tagLong = va_arg!long(_argptr);
				assert(type == TokenType.LITERAL_LONG);
			} else if (arg == typeid(ulong)) {
				tagULong = va_arg!ulong(_argptr);
				assert(type == TokenType.LITERAL_ULONG);
			} else if (arg == typeid(float)) {
				tagFlt = va_arg!float(_argptr);
				assert(type == TokenType.LITERAL_FLOAT);
			} else if (arg == typeid(double)) {
				tagDbl = va_arg!double(_argptr);
				assert(type == TokenType.LITERAL_DOUBLE);
			} else if (arg == typeid(string)) {
				tagStr = va_arg!string(_argptr);
				assert(type == TokenType.LITERAL_STR ||
					type == TokenType.LITERAL_CHAR ||
					type == TokenType.IDENTIFIER ||
					type == TokenType.KEYWORD);
			} else {
				assert(0);
			}
		}
	}
}

/**
 * Represents the current state of the lexer.
 */
enum LexState : ubyte {
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
	DList!Token tokens;
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
	void addToken(TokenType type) {
		ctx.tokens.insertBack(Token(type, ctx.line, ctx.col));
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
		uint radix;
		string pattern;
		
		if (ctx.state == LexState.LITERAL_INT_O) {
			radix = 8;
			pattern = "0-7";
		} else if (ctx.state == LexState.LITERAL_INT_D) {
			radix = 10;
			pattern = "0-9";
		} else if (ctx.state == LexState.LITERAL_INT_H) {
			radix = 16;
			pattern = "0-9A-Fa-f";
		} else {
			assert(0);
		}
		
		if (cur.length == 1 || !inPattern(cur[1], pattern)) {
			long literal;
			
			/* TODO: handle L/LL */
			/* TODO: handle unsigned literals: U/u */
			
			/* condition under which literal is int: no L/LL suffix, and within
			 * the 32-bit window: (0, 2^32-1) for unsigned, (-2^32, 2^32-1) for
			 * signed; otherwise, default to long for literals */
			
			try {
				literal = parse!long(buffer, radix);
			} catch (ConvOverflowException e) {
				stderr.writef("[lex|error|%u:%u] overflow in integer literal\n",
					ctx.line, ctx.col);
				exit(1);
			}
			
			/* implicitly promote literals if they won't fit in an int */
			if (/* no L && */literal >= int.min && literal <= int.max) {
				ctx.tokens.insertBack(Token(TokenType.LITERAL_INT,
					ctx.line, startCol, cast(int)literal));
			} else {
				ctx.tokens.insertBack(Token(TokenType.LITERAL_LONG,
					ctx.line, startCol, literal));
			}
			
			
			buffer.length = 0;
			ctx.state = LexState.DEFAULT;
			
			/+ TokenType type;
			
			if (ctx.state == LexState.LITERAL_INT_O) {
				type = TokenType.LITERAL_INT_O;
			} else if (ctx.state == LexState.LITERAL_INT_D) {
				type = TokenType.LITERAL_INT_D;
			} else if (ctx.state == LexState.LITERAL_INT_H) {
				type = TokenType.LITERAL_INT_H;
			} else {
				assert(0);
			}
			
			ctx.tokens.insertBack(Token(token, ctx.line, startCol,
				/+to!string(buffer)+/));
			
			buffer.length = 0;
			ctx.state = LexState.DEFAULT;+/
			
			
		}
		
		/* TODO: implement suffixes, floats
		 * for floats, if we are in base 10 int mode and come across a '.', then
		 * switch the mode to float and immediately call finishFloat */
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
			
			ctx.tokens.insertBack(Token((isKeyword ? TokenType.KEYWORD :
				TokenType.IDENTIFIER), ctx.line, startCol, identifier));
			
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
		} else if (escape == 'n') {
			buffer ~= '\n';
		} else if (escape == 'r') {
			buffer ~= '\r';
		} else if (escape == 't') {
			buffer ~= '\t';
		} else if (escape == 'v') {
			buffer ~= '\v';
		} else {
			stderr.writef("[lex|error|%u:%u] unknown escape sequence: '\\%c'\n",
				ctx.line, ctx.col, escape);
			exit(1);
		}
	}
	
	auto start = TickDuration.currSystemTick();
	
	/* TODO: sort these if/elseif/else chains in order of likelihood, once all
	 * cases have been added */
	
	while (cur.length > 0) {
		/* based on the current state, read a token and/or change the state */
		if (ctx.state == LexState.DEFAULT) {
			if (atNewLine()) {
				handleNewLine();
			} else if (cur[0] == '.') {
				addToken(TokenType.DOT);
			} else if (cur[0] == '-') {
				if (cur.length >= 2 && cur[1] == '>') {
					addToken(TokenType.ARROW);
					advance();
				}
			} else if (cur[0] == '~') {
				addToken(TokenType.NOT);
			} else if (cur[0] == '!') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.NOT_EQUAL);
					advance();
				} else {
					addToken(TokenType.BANG);
				}
			} else if (cur[0] == '=') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.EQUAL);
					advance();
				} else {
					addToken(TokenType.ASSIGN);
				}
			} else if (cur[0] == '^') {
				addToken(TokenType.XOR);
			} else if (cur[0] == '&') {
				if (cur.length >= 2 && cur[1] == '&') {
					addToken(TokenType.SS_AND);
					advance();
				} else {
					addToken(TokenType.AND);
				}
			} else if (cur[0] == '|') {
				if (cur.length >= 2 && cur[1] == '|') {
					addToken(TokenType.SS_OR);
					advance();
				} else {
					addToken(TokenType.OR);
				}
			} else if (cur[0] == '+') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.ASSIGN_ADD);
					advance();
				} else {
					addToken(TokenType.ADD);
				}
			} else if (cur[0] == '-') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.ASSIGN_SUBTRACT);
					advance();
				} else {
					addToken(TokenType.SUBTRACT);
				}
			} else if (cur[0] == '*') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.ASSIGN_MULTIPLY);
					advance();
				} else {
					addToken(TokenType.MULTIPLY);
				}
			} else if (cur[0] == '/') {
				if (cur.length >= 2 && cur[1] == '/') {
					advance();
					ctx.state = LexState.COMMENT_LINE;
				} else if (cur.length >= 2 && cur[1] == '*') {
					advance();
					ctx.state = LexState.COMMENT_BLOCK;
				} else if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.ASSIGN_DIVIDE);
					advance();
				} else {
					addToken(TokenType.DIVIDE);
				}
			} else if (cur[0] == '%') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.ASSIGN_MODULO);
					advance();
				} else {
					addToken(TokenType.MODULO);
				}
			} else if (cur[0] == ';') {
				addToken(TokenType.SEMICOLON);
			} else if (cur[0] == ',') {
				addToken(TokenType.COMMA);
			} else if (cur[0] == '{') {
				addToken(TokenType.BRACE_OPEN);
			} else if (cur[0] == '}') {
				addToken(TokenType.BRACE_CLOSE);
			} else if (cur[0] == '(') {
				addToken(TokenType.PAREN_OPEN);
			} else if (cur[0] == ')') {
				addToken(TokenType.PAREN_CLOSE);
			} else if (cur[0] == '[') {
				addToken(TokenType.BRACKET_OPEN);
			} else if (cur[0] == ']') {
				addToken(TokenType.BRACKET_CLOSE);
			} else if (cur[0] == '<') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.LESS_EQUAL);
					advance();
				} else {
					addToken(TokenType.LESS);
				}
			} else if (cur[0] == '>') {
				if (cur.length >= 2 && cur[1] == '=') {
					addToken(TokenType.GREATER_EQUAL);
					advance();
				} else {
					addToken(TokenType.GREATER);
				}
			} else if (cur[0] == '"') {
				startCol = ctx.col;
				ctx.state = LexState.LITERAL_STR;
			} else if (cur[0] == '\'') {
				startCol = ctx.col;
				ctx.state = LexState.LITERAL_CHAR;
			} else if (inPattern(cur[0], "0-9")) {
				startCol = ctx.col;
				
				if (cur[0] == '0') {
					if (cur.length >= 2 && toLower(cur[1]) == 'x') {
						advance();
						ctx.state = LexState.LITERAL_INT_H;
					} else {
						buffer ~= cur[0];
						ctx.state = LexState.LITERAL_INT_O;
					}
				} else {
					buffer ~= cur[0];
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
				stderr.writef("[lex|error|%u:%u] unexpected character: " ~
					"'%c'\n", ctx.line, ctx.col, cur[0]);
				stderr.write("TODO: make this error fatal\n");
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
						stderr.writef("[lex|error|%u:%u] escape sequence " ~
							"interrupted by newline\n", ctx.line, ctx.col);
						exit(1);
					} else {
						appendEscapeChar(cur[1]);
						advance();
					}
				} else {
					stderr.writef("[lex|err|%u:%u] found an incomplete " ~
						"escape sequence\n", ctx.line, ctx.col);
					exit(1);
				}
			} else if (ctx.state == LexState.LITERAL_STR && cur[0] == '"') {
				ctx.tokens.insertBack(Token(TokenType.LITERAL_STR, ctx.line,
					ctx.col, to!string(buffer)));
				
				buffer.length = 0;
				ctx.state = LexState.DEFAULT;
			} else if (ctx.state == LexState.LITERAL_CHAR && cur[0] == '\'') {
				if (buffer.length == 0) {
					stderr.writef("[lex|error|%u:%u] found an empty char " ~
						"literal\n", ctx.line, ctx.col);
					exit(1);
				} else if (buffer.length > 1) {
					stderr.writef("[lex|error|%u:%u] found a char literal " ~
						"with too many chars\n", ctx.line, ctx.col);
					exit(1);
				}
				
				ctx.tokens.insertBack(Token(TokenType.LITERAL_CHAR, ctx.line,
					ctx.col, to!string(buffer)));
				
				buffer.length = 0;
				ctx.state = LexState.DEFAULT;
			} else if (cur[0] == '\n' || cur[0] == '\r') {
				stderr.writef("[lex|error|%u:%u] encountered a newline " ~
					"within a %s literal\n", ctx.line, ctx.col, (ctx.state ==
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
	
	ctx.tokens.insertBack(Token(TokenType.EOF, ctx.line, 0));
	
	/* determine if the state in which we find ourselves after EOF is correct */
	if (ctx.state == LexState.COMMENT_BLOCK) {
		stderr.writef("[lex|error|%u:%u] encountered EOF while still in a " ~
			"comment block\n", ctx.line, ctx.col);
		exit(1);
	} else if (ctx.state == LexState.LITERAL_STR) {
		stderr.writef("[lex|error|%u:%u] encountered EOF while still in a " ~
			"string literal\n", ctx.line, ctx.col);
		exit(1);
	}
	
	write("[lex] tokens:\n");
	foreach (token; ctx.tokens) {
		string tag;
		
		switch (token.type) {
		case TokenType.LITERAL_STR:
		case TokenType.LITERAL_CHAR:
		case TokenType.IDENTIFIER:
		case TokenType.KEYWORD:
			tag = " [%s]".format(token.tagStr);
			break;
		case TokenType.LITERAL_INT:
			tag = " [%d]".format(token.tagInt);
			break;
		case TokenType.LITERAL_UINT:
			tag = " [%u]".format(token.tagUInt);
			break;
		case TokenType.LITERAL_LONG:
			tag = " [%d]".format(token.tagLong);
			break;
		case TokenType.LITERAL_ULONG:
			tag = " [%u]".format(token.tagULong);
			break;
		case TokenType.LITERAL_FLOAT:
			tag = " [%f]".format(token.tagFlt);
			break;
		case TokenType.LITERAL_DOUBLE:
			tag = " [%f]".format(token.tagDbl);
			break;
		default:
			tag = "";
		}
		
		writef("line%4u  col %2u:  %s%s\n",
			token.line, token.col, token.type, tag);
	}
	
	auto finish = TickDuration.currSystemTick();
	long duration = finish.msecs() - start.msecs();
	if (duration >= 0) {
		stderr.writef("[lex] took %d.%03d seconds\n",
			duration / 1000, duration % 1000);
	} else {
		stderr.write("[lex|warn] duration is negative?!\n");
	}
	
	return ctx;
}
