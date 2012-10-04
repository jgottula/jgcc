/++
 + Authors:   Justin Gottula
 + Date:      October 2012
 + License:   Simplified BSD license
 +/
module lex;

import std.container;
import std.stdio;


/++
 + Represents an individual token.
 +/
enum Token : ushort {
	T_EOF          = 0,
	T_KEYWORD      = 1,
	T_LITERAL_INT  = 2,
}

/++
 + Combines a Token enum with a string tag (for identifiers, keywords, etc.).
 +/
struct TokenTag {
	Token token;
	string tag;
}

/++
 + Represents the current state of the lexer.
 +/
enum LexState : ushort {
	DEFAULT = 0,
	COMMENT = 1,
}

/++
 + Contains the lexer's state and the list of processed tokens.
 +/
struct LexContext {
	SList!TokenTag tokens;
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
	char peek(ulong offset = 0) {
		if (avail() <= offset)
			throw new LexOverrunException();
		
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
	void advance(ulong count = 1) {
		if (avail() < count)
			throw new LexOverrunException();
		
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
	
	while (lexFile.avail() > 0)
	{
		char c = lexFile.peek();
		
		if (ctx.state == LexState.DEFAULT) {
			
		} else if (ctx.state == LexState.COMMENT) {
			
		} else {
			
		}
		
		writef("%c", c);
		
		lexFile.advance();
	}
	
	// TODO: decide if the state we are left in at EOF time is okay
	
	return ctx;
}
