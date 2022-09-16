#!/usr/bin/make

# Could be .cpp, .cc, ... but only one.
CXX_EXTENSION := .cc

# To detect a main() function in a source file.
MAIN_REGEX = int[[:space:]]+main[[:space:]]*\(

SOURCES := $(shell find . -name \*$(CXX_EXTENSION))

# Anything that mentions a main function is a program source.
PROG_SOURCES := $(shell grep -El '$(MAIN_REGEX)' $(SOURCES))
NONPROG_SOURCES := $(filter-out $(PROG_SOURCES),$(SOURCES))

OBJECTS = $(patsubst %$(CXX_EXTENSION),%.o,$(SOURCES))

PROG_OBJECTS = $(patsubst %$(CXX_EXTENSION),%.o,$(PROG_SOURCES))
NONPROG_OBJECTS = $(patsubst %$(CXX_EXTENSION),%.o,$(NONPROG_SOURCES))

PROGS = $(patsubst %$(CXX_EXTENSION),%,$(PROG_SOURCES))

CONVLIB = libproj.a
LDFLAGS += -L. -lproj

$(PROGS): $(CONVLIB) $(PROG_OBJECTS)

%: %.o
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

$(CONVLIB): $(NONPROG_OBJECTS)
	ar rcs $@ $^

clean:
	rm -f $(OBJECTS) $(PROGS) $(CONVLIB)

.PHONY: clean
