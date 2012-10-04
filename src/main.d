module main;

import std.c.stdlib;
import std.stdio;

import input;
import lex;


void main(string[] args)
{
	stderr.write("jgcc: justin gottula's c compiler\n" ~
		"      (c) 2012 justin gottula\n\n");
	
	if (args.length != 2) {
		stderr.write("[main] expected one argument: source file\n");
		exit(1);
	}
	
	File inputFile = getInputFile(args[1]);
	LexContext lexCtx = doLex(inputFile);
}
