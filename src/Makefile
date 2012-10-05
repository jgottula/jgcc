# jgcc
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

PROJNAME:=jgcc
LIBS:=

DC:=ldc2
DFLAGS:=-w -wi -O1 -g -d-debug -disable-inlining -output-o -unittest
DOCFLAGS:=-O0 -D

OUT_EXE:=$(PROJNAME)

# evaluated when used
SOURCES=$(wildcard *.d)
OBJECTS=$(patsubst %.d,%.o,$(SOURCES))
DOCS=$(patsubst %.d,../doc/%.html,$(SOURCES))
CLEAN=$(wildcard jgcc) $(wildcard *.o) $(wildcard ../doc/*.html)


.PHONY: all clean

# default rule
all: $(PROJNAME)

$(PROJNAME): $(OBJECTS)
	$(DC) $(DFLAGS) $(LIBS) -of=$@ $^

%.o: %.d Makefile
	$(DC) $(DFLAGS) -Dd=../doc -c $<

clean:
	rm -f $(CLEAN)
