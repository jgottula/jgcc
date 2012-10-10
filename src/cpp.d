/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module cpp;

import std.conv;
import std.stdio;
import std.string;


enum CPPState {
	DEFAULT,
	COMMENT_BLOCK, COMMENT_LINE,
	PREPROCESSOR,
	PP_INCLUDE,
	PP_IF, PP_ELIF,
	PP_IFDEF, PP_IFNDEF,
}


/**
 * Preprocesses the source contained in before, and writes the processed output
 * to after
 * 
 * Params:
 * before =
 *  string containing source code
 * after =
 *  string which will contain the preprocessor's output
 */
void preProcess(in string before, out string after) {
	auto state = CPPState.DEFAULT;
	string cur = before;
	char[] buffer = new char[0];
	
	/* TODO: invent a way to map original source lines/cols to preprocessed
	 * lines and cols so the lexer can annotate tokens' lines/cols correctly
	 * 
	 * there should be a new struct with cpp context information, which will
	 * contain a (probably) linked list containing a series of structs which
	 * each represent an instance in which the cpp added lines, removed lines,
	 * added columns, removed columns, etc.
	 * 
	 * this way, the lexer can easily compute what the _original_ line number of
	 * a particular bit of source code was
	 */
	
	while (cur.length > 0) {
		if (state == CPPState.DEFAULT) {
			if (cur[0] == '/' && cur.length >= 2) {
				if (cur[1] == '*') {
					cur = cur[1..$];
					state = CPPState.COMMENT_BLOCK;
				} else if (cur[1] == '/') {
					cur = cur[1..$];
					state = CPPState.COMMENT_LINE;
				} else {
					buffer ~= cur[0];
				}
			} else if (cur[0] == '#') {
				state = CPPState.PREPROCESSOR;
			} else {
				buffer ~= cur[0];
			}
		} else if (state == CPPState.COMMENT_BLOCK) {
			if (cur.length >= 2 && cur[0] == '*' && cur[1] == '/') {
				cur = cur[1..$];
				state = CPPState.DEFAULT;
			}
		} else if (state == CPPState.COMMENT_LINE) {
			if (cur[0] == '\r' || cur[0] == '\n') {
				buffer ~= cur[0];
				state = CPPState.DEFAULT;
			}
		} else if (state == CPPState.PREPROCESSOR) {
			if (cur[0] == '\r' || cur[0] == '\n') {
				buffer ~= cur[0];
				state = CPPState.DEFAULT;
			} else {
				/* TODO: preprocessor stuff */
			}
		} else if (state == CPPState.PP_INCLUDE) {
			/* ... */
		} else {
			assert(0);
		}
		
		/+buffer ~= cur[0];+/
		cur = cur[1..$];
	}
	
	/* determine if the state in which we find ourselves after EOF is correct */
	if (state == CPPState.COMMENT_BLOCK) {
		stderr.writef("[cpp|error|%d:%d] encountered EOF while still in a " ~
			"block comment\n");
		exit(1);
	} /+else if (...+/
	
	after = to!string(buffer);
	
	stderr.write("--------------------------------- SOURCE DUMP " ~
		"----------------------------------\n");
	foreach (ulong num, line; before.splitLines()) {
		stderr.writef("%3d|%s\n", num + 1, line);
	}
	stderr.write("---------------------------------- CPP OUTPUT " ~
		"----------------------------------\n");
	foreach (ulong num, line; after.splitLines()) {
		stderr.writef("%3u|%s\n", num + 1, line);
	}
	stderr.write("----------------------------------------------" ~
		"----------------------------------\n");
}
