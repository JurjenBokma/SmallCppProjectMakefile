#!/usr/bin/make

# Extensions can be set here.
CXX_EXTENSION = .cc
# Some use .h
HEADER_EXTENSION = .hh
INTERNAL_HEADER_EXTENSION = .ih
PCH_EXTENSION = .ih.gch

## No editing below this line unless you know what you're doing. ##

# To see executed commands, on the command line set QUIET=
QUIET ?= @

# For a graph of the build process.
DOTFILE = build.dot
BUILDLOG = build.log

# To detect a main() function in a source file.
MAIN_REGEX = int[[:space:]]+main[[:space:]]*\(

# For use in build.dot
SED_NEWLINE_ESCAPE = s%/%/\\n%g

SOURCES := $(patsubst ./%,%,$(shell find . -name \*$(CXX_EXTENSION)))
INTERNAL_HEADERS := $(patsubst ./%,%,$(shell find . -name \*$(INTERNAL_HEADER_EXTENSION)))

# Anything that mentions a main function is a program source.
PROG_SOURCES := $(shell grep -El '$(MAIN_REGEX)' $(SOURCES))
NONPROG_SOURCES := $(filter-out $(PROG_SOURCES),$(SOURCES))

OBJECTS = $(patsubst %$(CXX_EXTENSION),%.o,$(SOURCES))
PRECOMPILED_HEADERS = $(patsubst %,%.gch,$(INTERNAL_HEADERS))

PROG_OBJECTS = $(patsubst %$(CXX_EXTENSION),%.o,$(PROG_SOURCES))
NONPROG_OBJECTS = $(patsubst %$(CXX_EXTENSION),%.o,$(NONPROG_SOURCES))

PROGS = $(patsubst %$(CXX_EXTENSION),%,$(PROG_SOURCES))

CONVLIB = libproj.a
LDFLAGS += -L. -lproj

# Use generated dependencies.
DEPDIR = generated_deps
DEPFLAGS = -fpch-deps -MQ $@ -MMD -MP -MF $<.dep
CXXFLAGS += $(DEPFLAGS)

DEP_FILES = $(patsubst %,%.dep,$(SOURCES) $(INTERNAL_HEADERS))



# Default target: make all progs
all: $(PROGS)

# All programs need the convenience library.
$(PROGS): $(CONVLIB)
$(PROGS): ACTION = Linking

# To make the convenience library, we need all non-prog objects.
$(CONVLIB): $(NONPROG_OBJECTS)
	$(QUIET) ar rcs $@ $^
	@echo "$(foreach OBJ,$(NONPROG_OBJECTS),\"$(OBJ)\" -> \"$(CONVLIB)\" [label=\"copy\"];\n)" >> $(BUILDLOG)
$(CONVLIB): ACTION = Gathering

# Pattern rule:
# If the program object is newer, we (re-)link it against the convenience library.
$(PROGS): %: %.o
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $< $(LDFLAGS)
	@echo "\"$(filter %.o,$^)\" -> \"$@\" [label=\"link\"];\n" >> $(BUILDLOG)
	@echo "\"$(filter %.a,$^)\" -> \"$@\" [label=\"link\"];\n" >> $(BUILDLOG)

# If the source is newer, we compile it.
$(OBJECTS): %.o: %$(CXX_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
	@echo "\"$<\" -> \"$@\" [label=\"comp\"];\n" >> $(BUILDLOG)
	@echo "$(foreach IH,$(filter %$(INTERNAL_HEADER_EXTENSION),$^),\"$(IH)\" -> \"$@\" [label=\"inc\"];\n)" | sed 's/\$(INTERNAL_HEADER_EXTENSION)/$(PCH_EXTENSION)/g' >> $(BUILDLOG)
$(OBJECTS): ACTION = Compiling

# Pattern rule: before updating any objects, update all precompiled headers.
# (This is a waste when making only one object, but keeps the Makefile simpler.)
$(OBJECTS): %.o:  $(PRECOMPILED_HEADERS)

# To compile a precompiled header, specify it's a header.
$(PRECOMPILED_HEADERS): CXXFLAGS += -x c++-header

# Pattern rule: each precompiled header depends on its internal header.
$(PRECOMPILED_HEADERS): %$(PCH_EXTENSION): %$(INTERNAL_HEADER_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<
	@echo "\"$<\" -> \"$@\" [label=\"precomp\"];\n" >> $(BUILDLOG)
	@echo "$(foreach IH,$(filter %$(INTERNAL_HEADER_EXTENSION),$^),\"$(IH)\" -> \"$@\" [label=\"inc\"];\n)" >> $(BUILDLOG)

$(PRECOMPILED_HEADERS): ACTION = Pre-compiling

clean: graphclean
	$(QUIET) rm -f $(DOTFILE) $(DEP_FILES)

# To get a nice graph, remove all but deps.
# So run make graphclean ; make graph
graphclean:
	$(QUIET) rm -f $(BUILDLOG) $(PRECOMPILED_HEADERS) $(OBJECTS) $(CONVLIB) $(PROGS)

.PHONY: clean

graph: $(DOTFILE)
$(DOTFILE): build.log
	@echo "strict digraph {" > $@
	@echo "rankdir=LR" >> $@
	@echo "{rank=same $(foreach SOURCE,$(SOURCES),\"$(SOURCE)\";)}" |sed '$(SED_NEWLINE_ESCAPE)' >> $@
	@echo "{rank=same $(foreach OBJECT,$(OBJECTS),\"$(OBJECT)\";)}" |sed '$(SED_NEWLINE_ESCAPE)' >> $@
	@echo "{rank=same $(foreach IH,$(INTERNAL_HEADERS),\"$(IH)\";)}" |sed '$(SED_NEWLINE_ESCAPE)' >> $@
	@echo "{rank=same $(foreach PCH,$(PRECOMPILED_HEADERS),\"$(PCH)\";)}" |sed '$(SED_NEWLINE_ESCAPE)' >> $@
	@cat $< |sed '$(SED_NEWLINE_ESCAPE)' >> $@
	@echo "$(foreach IH,$(INTERNAL_HEADERS),$(foreach HEADER,$(shell fgrep -e '^#include[[:space:]]+"' $(IH)),\"$(HEADER)\" -> \"$(IH)\" [label=\"inc\"];\n))" >> $@
	@echo "}" >> $@
	@echo "$@ made"

# Only include generated dependencies if actually found.
-include $(DEP_FILES)
