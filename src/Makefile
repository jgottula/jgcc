# jgcc
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

PROJNAME:=jgcc
LIBS:=

DFLAGS:=-Wall -O1 -ggdb3 -funittest -fdoc -fdoc-dir=../doc
LINKFLAGS:=-fwhole-program -fuse-linker-plugin $(LIBS)

OUT_EXE:=$(PROJNAME)

# evaluated when used
SOURCES=$(wildcard *.d)
OBJECTS=$(patsubst %.d,%.o,$(SOURCES))
CLEAN=$(OUT_EXE) $(wildcard *.o)


.PHONY: all clean

# default rule
all: $(PROJNAME)

$(PROJNAME): $(OBJECTS)
	gdc $(LINKFLAGS) -o $@ $^

%.o: %.d Makefile
	gdc $(DFLAGS) -c $<

clean:
	rm -f $(CLEAN)
