/++
 + Authors: Justin Gottula
 + Date:    October 2012
 + License: Simplified BSD license
 +/
module cpp;

import std.conv;
import std.stdio;


/++
 + Preprocesses the source contained in before, and writes the processed output
 + to after
 + 
 + Params:
 + before =
 +  string containing source code
 + after =
 +  string which will contain the preprocessor's output
 +/
void preProcess(in string before, out string after) {
	string cur = before;
	char[] buffer = new char[0];
	
	while (cur.length > 0) {
		buffer ~= cur[0];
		cur = cur[1..$];
	}
	
	after = to!string(buffer);
	
	stderr.write("---- CPP OUTPUT -----\n");
	stderr.write(after);
	stderr.write("\n---------------------\n");
}
