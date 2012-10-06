/**
 * Authors: Justin Gottula
 * Date:    October 2012
 * License: Simplified BSD license
 */
module main;

import std.c.stdlib;
import std.stdio;

import cpp;
import input;
import lex;


void main(string[] args) {
	stderr.write("jgcc: justin gottula's c compiler\n" ~
		"      (c) 2012 justin gottula\n\n");
	
	if (args.length != 2) {
		stderr.write("[main|error] expected one argument: source file\n");
		exit(1);
	}
	
	string source, cppSource;
	readSource(args[1], source);
	preProcess(source, cppSource);
	LexContext lexCtx = lexSource(source);
}
