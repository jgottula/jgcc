# jgcc
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

PROJNAME:=jgcc

DFLAGS:=-Wall -Wextra -O1 -ggdb3 -fwhole-program -fuse-linker-plugin -DDEBUG
LIBS:=

OUT_EXE:=$(PROJNAME)

# evaluated when used
SOURCES=$(wildcard *.d)
OBJECTS=$(patsubst %.d,%.o,$(SOURCES))
CLEAN=$(OUT_EXE) $(wildcard *.o)


.PHONY: all clean

# default rule
all: $(PROJNAME)

$(PROJNAME): $(OBJECTS)
	gdc $(DFLAGS) -o $@ $^

%.o: %.d Makefile
	gdc $(DFLAGS) -c $<

clean:
	rm -f $(CLEAN)
