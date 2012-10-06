/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module cpp;

import std.conv;
import std.stdio;
import std.string;


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
		buffer ~= cur[0];
		cur = cur[1..$];
	}
	
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
