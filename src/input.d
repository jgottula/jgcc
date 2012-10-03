module input;

import std.c.stdlib;
import std.exception;
import std.file;
import std.stdio;


File getInputFile(string inputPath)
{
	if (inputPath.length < 3 || inputPath[$-2..$] != ".c")
	{
		stderr.write("[input] expected a file ending in '.c'\n");
		exit(1);
	}
	
	if (!exists(inputPath))
	{
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
	
	return inputFile;
}
