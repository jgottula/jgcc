# jgcc
# (c) 2012 Justin Gottula
# The source code of this project is distributed under the terms of the
# simplified BSD license. See the LICENSE file for details.

# project makefile

PROJNAME:=jgcc
LIBS:=

# -funittest is exceptionally slow
DFLAGS:=-Wall -O1 -ggdb3 -pipe
DOCFLAGS:=-O0 -fdoc
LINKFLAGS:=-fwhole-program -fuse-linker-plugin -pipe $(LIBS)

OUT_EXE:=$(PROJNAME)

# evaluated when used
SOURCES=$(wildcard *.d)
OBJECTS=$(patsubst %.d,%.o,$(SOURCES))
DOCS=$(patsubst %.d,../doc/%.html,$(SOURCES))
CLEAN=$(wildcard jgcc) $(wildcard *.o) $(wildcard ../doc/*.html)


.PHONY: all doc clean

# default rule
all: $(PROJNAME) doc

$(PROJNAME): $(OBJECTS)
	gdc $(LINKFLAGS) -o $@ $^

doc: $(DOCS)

../doc/%.html: %.d Makefile
	gdc $(DOCFLAGS) -fdoc-file=$@ -o /dev/null -c $<

%.o: %.d Makefile
	gdc $(DFLAGS) -c $<

clean:
	rm -f $(CLEAN)
