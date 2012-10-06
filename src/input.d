/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module input;

import std.c.stdlib;
import std.conv;
import std.exception;
import std.file;
import std.stdio;
import std.string;


/**
 * Determines whether inputPath is valid, opens the file, and reads its contents
 * into memory
 * 
 * Params:
 * inputPath =
 *  the file path of the source file to be opened
 * fileContents =
 *  a string which will contain the full contents of the file
 */
void readSource(in string inputPath, out string fileContents) {
	if (inputPath.length < 3 || inputPath[$-2..$] != ".c") {
		stderr.write("[input] expected a file ending in '.c'\n");
		exit(1);
	}
	
	if (!inputPath.exists()) {
		stderr.writef("[input] the source file '%s' does not exist\n",
			inputPath);
		exit(1);
	}
	
	File inputFile;
	
	try {
		inputFile = File(inputPath, "r");
	}
	catch (ErrnoException e) {
		stderr.writef("[input] encountered an IO error (errno = %d):\n%s\n",
			e.errno, e.msg);
		exit(1);
	}
	
	inputFile.seek(0, SEEK_END);
	char[] buffer = new char[inputFile.tell()];
	
	inputFile.seek(0, SEEK_SET);
	inputFile.rawRead(buffer);
	
	fileContents = to!string(buffer);
	
	stderr.write("--------------------------------- SOURCE DUMP " ~
		"----------------------------------\n");
	foreach (ulong num, line; fileContents.splitLines()) {
		stderr.writef("%3d|%s\n", num + 1, line);
	}
	stderr.write("----------------------------------------------" ~
		"----------------------------------\n");
}
