module lex;

import std.container;
import std.stdio;


enum Token : ushort {
	T_EOF     = 0,
	T_KEYWORD = 1,
}

struct TokenTag {
	Token token;
	string tag;
}

struct LexContext {
	SList!TokenTag tokens;
}

enum LexState : ushort {
	DEFAULT = 0,
}


LexContext lexFile(File inputFile)
{
	auto state = LexState.DEFAULT;
	auto ctx = LexContext();
	
	writef("file begin\n|");
	char c;
	while (inputFile.readf("%c", &c) == 1) {
		writef("%c", c);
	}
	writef("| file end\n");
	
	return ctx;
}
