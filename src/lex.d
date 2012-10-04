/++
 + Authors:   Justin Gottula
 + Date:      October 2012
 + License:   Simplified BSD license
 +/
module lex;

import std.c.stdlib;
import std.container;
import std.conv;
import std.stdio;
import std.string;


/++
 + Represents an individual token.
 +/
enum Token : ushort {
	EOF          = 0,
	IDENTIFIER   = 1,
	KEYWORD      = 2,
	LITERAL_INT  = 3,
	LITERAL_CHAR = 4,
	LITERAL_STR  = 5,
}

/++
 + Combines a Token enum with a string tag (for identifiers, keywords, etc.).
 +/
struct TokenTag {
	Token token;
	string tag;
	
	/++
	 + Initializes the class with token and no tag.
	 +/
	this(Token token) {
		this.token = token;
	}
}

/++
 + Represents the current state of the lexer.
 +/
enum LexState : ushort {
	DEFAULT       = 0,
	COMMENT_BLOCK = 1,
	COMMENT_LINE  = 2,
	IDENTIFIER    = 3,
}

/++
 + Contains the lexer's state and the list of processed tokens.
 +/
struct LexContext {
	DList!TokenTag tokens;
	LexState state;
}

/++
 + Encapsulates a File struct with access methods suitable to a lexer.
 +/
class LexFile {
	/++
	 + Creates a new wrapper from an already-opened File struct.
	 + 
	 + Params:
	 + file =
	 +  an already opened File struct
	 +/
	this(File file) {
		this.cur = 0;
		
		file.seek(0, SEEK_END);
		this.len = file.tell();
		file.rewind();
		
		this.file = file;
	}
	
	/++
	 + Indicates the current cursor position in the file.
	 + 
	 + Returns: the current cursor index
	 +/
	ulong tell() {
		return cur;
	}
	
	/++
	 + Indicates how much of the file is left.
	 + 
	 + Returns: the number of characters left in the file
	 +/
	ulong avail() {
		return len - cur;
	}
	
	/++
	 + Peeks at a character at or past the cursor.
	 + 
	 + Params:
	 + offset =
	 +  optionally, the number of positions past the cursor at which to read
	 + Returns: the character located offset positions past the cursor, without
	 + modifying the cursor
	 + Throws: LexOverrunException if a character past the end of the file is
	 + requested
	 +/
	char peek(in ulong offset = 0) {
		if (avail() <= offset) {
			throw new LexOverrunException();
		}
		
		char c;
		file.seek(offset, SEEK_CUR);
		assert(file.readf("%c", &c) == 1);
		file.seek(cur, SEEK_SET);
		
		return c;
	}
	
	/++
	 + Advances the cursor by count positions.
	 + 
	 + Params:
	 + count =
	 +  optionally, the number of positions by which to _advance the cursor
	 + Throws: LexOverrunException  if the requested advancement will place the
	 + cursor past the end of the file (but not if the advancement places the
	 + cursor just past the last character in the file)
	 +/
	void advance(in ulong count = 1) {
		if (avail() < count) {
			throw new LexOverrunException();
		}
		
		cur += count;
		file.seek(count, SEEK_CUR);
	}
	
private:
	File file;
	ulong cur, len;
}

/++
 + Indicates that the lexer has attempted to read or advance past the end of the
 + file.
 +/
class LexOverrunException : Exception {
	this() {
		super("");
	}
}


/++
 + Lexes the contents of inputFile.
 + 
 + Params:
 + inputFile =
 +  an already opened File struct representing the source file to lex
 + Returns: a LexContext struct containing the list of tokens found in the file
 +/
LexContext doLex(File inputFile) {
	auto lexFile = new LexFile(inputFile);
	auto ctx = LexContext();
	char[] buffer = new char[1024];
	uint bufLen = 0;
	
	/++
	 + Checks if an identifier has been completed and, if so, adds it as a
	 + token.
	 +/
	void finishIdentifier() {
		if (lexFile.avail() < 1 || !inPattern(lexFile.peek(1), "A-Za-z0-9_")) {
			auto token = TokenTag(Token.IDENTIFIER);
			token.tag = to!string(buffer[0..bufLen]);
			ctx.tokens.insertBack(token);
			
			bufLen = 0;
			ctx.state = LexState.DEFAULT;
		}
	}
	
	while (lexFile.avail() > 0) {
		char c = lexFile.peek();
		
		/* NOTE! for multi-char tokens, peek ahead one character and, if it is
		 * not part of the token (i.e., no longer [A-Z]|[a-z]|_) then revert the
		 * state back to DEFAULT */
		
		/* based on the current state, read a token and/or change the state */
		if (ctx.state == LexState.DEFAULT) {
			if (c == '/') {
				if (lexFile.avail() >= 1) {
					if (lexFile.peek(1) == '/') {
						lexFile.advance();
						ctx.state = LexState.COMMENT_LINE;
					} else if (lexFile.peek(1) == '*') {
						lexFile.advance();
						ctx.state = LexState.COMMENT_BLOCK;
					}
				}
			} else if (inPattern(c, "A-Za-z_")) {
				buffer[bufLen++] = c;
				finishIdentifier();
				
				ctx.state = LexState.IDENTIFIER;
			}
			
			/* simple echo for characters not eliminated by comments */
			if (ctx.state == LexState.DEFAULT) {
				writef("%c", c);
			}
		} else if (ctx.state == LexState.COMMENT_BLOCK) {
			if (c == '*') {
				if (lexFile.avail() >= 1 && lexFile.peek(1) == '/') {
					lexFile.advance();
					ctx.state = LexState.DEFAULT;
				}
			}
		} else if (ctx.state == LexState.COMMENT_LINE) {
			if (c == '\n' || c == '\r') {
				/* deal with \r\n and \n\r line endings */
				if (lexFile.avail() >= 1) {
					if (c == '\n' && lexFile.peek(1) == '\r') {
						lexFile.advance();
					} else if (c == '\r' && lexFile.peek(1) == '\n') {
						lexFile.advance();
					}
				}
				
				ctx.state = LexState.DEFAULT;
			}
		} else if (ctx.state == LexState.IDENTIFIER) {
			buffer[bufLen++] = c;
			
			finishIdentifier();
		} else {
			
		}
		
		lexFile.advance();
	}
	
	ctx.tokens.insertBack(TokenTag(Token.EOF));
	
	/* determine if the state in which we find ourselves after EOF is correct */
	if (ctx.state == LexState.COMMENT_BLOCK) {
		stderr.write("[lex] encountered EOF while still in a comment block\n");
		exit(1);
	}
	
	foreach (t; ctx.tokens) {
		writef("token: %s [%s]\n", t.token, t.tag);
	}
	
	return ctx;
}
