#!/usr/bin/make

# Extensions can be set here.
CXX_EXTENSION = cc
# Some use .h
HEADER_EXTENSION = hh
INTERNAL_HEADER_EXTENSION = ih
PCH_EXTENSION = ih.gch

## No editing below this line unless you know what you're doing. ##

# There are many words for true and false. But all other words cause an error.
boolalpha = $(or \
   $(if $(filter $(1),t true  True  TRUE  yes Yes YES YESS! on  On  ON  one  One  ONE  1),true,),\
   $(if $(filter $(1),f false False FALSE no  No  NO  NOO!  off Off OFF zero Zero ZERO 0),false,),\
   $(if $(strip $(1)),,false),\
   $(error cannot interpret $(1) as boolean)\
)

# Help: Try: 'make VERBOSE=1'
QUIET := $(if $(filter true,$(call boolalpha,$(VERBOSE))),,@)

# We use precompiled headers by default. Try: make PCH=no
PCH ?= true
USE_PRECOMPILED_HEADERS := $(call boolalpha,$(PCH))

# We heed generated dependencies by default. Try: make DEP=no
# Once without deps, 'make clean' is needed to get them back on the next make.
DEP ?= true
USE_GENERATED_DEPENDENCIES := $(call boolalpha,$(DEP))
#$(info USE_GENERATED_DEPENDENCIES = $(USE_GENERATED_DEPENDENCIES))

# Recursive wildcard to find all files in the current directory and subdirs.
# Using a $(shell find...) would also work, but depend on the find utility.
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# Simply list all files we can find.
ALL_FILES := $(patsubst ./%,%,$(call rwildcard,.,*))

# Anything with a CXX_EXTENSION is a C++ file.
SOURCES = $(filter %.$(CXX_EXTENSION),$(ALL_FILES))
# Get object names by replacing the extension.
OBJECTS = $(patsubst %.$(CXX_EXTENSION),%.o,$(SOURCES))

# To detect a main() function in a source file.
# Not bulletproof, but KISS.
MAIN_REGEX = int[[:space:]]+main[[:space:]]*\(

# Anything that mentions a main function is a program source.
PROG_SOURCES := $(shell grep -El '$(MAIN_REGEX)' $(SOURCES))
PROG_OBJECTS = $(patsubst %.$(CXX_EXTENSION),%.o,$(PROG_SOURCES))
PROGS = $(patsubst %.$(CXX_EXTENSION),%,$(PROG_SOURCES))
TESTPROGS = $(filter tests/%,$(PROGS))

# Sources that aren't program sources, are non-program sources.
NONPROG_SOURCES = $(filter-out $(PROG_SOURCES),$(SOURCES))
NONPROG_OBJECTS = $(patsubst %.$(CXX_EXTENSION),%.o,$(NONPROG_SOURCES))

# From every internal header we can build a precompiled (internal) header.
INTERNAL_HEADERS = $(filter %.$(INTERNAL_HEADER_EXTENSION),$(ALL_FILES))

PRECOMPILED_HEADERS = $(patsubst %,%.gch,$(INTERNAL_HEADERS))

# The name of our convenience library.
CONVLIB = libproj.a
# Always link against the convenience library.
LDFLAGS += -L. -lproj

###

# Default target: to make all programs.
all: $(PROGS)

# All programs need the convenience library.
$(PROGS): $(CONVLIB)

# To create an executable program is called: 'Linking'.
$(PROGS): ACTION = Linking
$(CONVLIB): ACTION = Gathering
$(OBJECTS): ACTION = Compiling
$(PRECOMPILED_HEADERS): ACTION = Pre-compiling

# When compiling a precompiled header, specify that it's a header.
$(PRECOMPILED_HEADERS): CXXFLAGS += -x c++-header

# A rule actually says two things:
# 1. To build any of the target, i.e. $(CONVLIB),
#    we need the prerequisites, i.e. $(NONPROG_OBJECTS)
# 2. If any of the preprequisites are newer than the target,
#    we need to rebuild the target.
$(CONVLIB): $(NONPROG_OBJECTS)
	@echo "    [ $(ACTION) $@ <- $^ ]"
	$(QUIET) ar rcs $@ $^
# In the recipe of the rule,
# $@ is the target, i.e. $(CONVLIB)
# $^ is the list of preprequisites, i.e. $(NONPROG_OBJECTS)

# Pattern rule:
# If any program object file is newer than the program itself,
# we rebuild the program, by linking the object file against the convenience library.
$(PROGS): %: %.o
	@echo "    [ $(ACTION) $@ <- $^ ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

# If the source is newer than its object, we compile it.
$(OBJECTS): %.o: %.$(CXX_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

# Clean everything except the programs.
mostlyclean:
	$(QUIET) rm -f $(DEP_FILES) $(PRECOMPILED_HEADERS) $(OBJECTS) $(CONVLIB)

# Remove everything Make created.
clean: mostlyclean
	$(QUIET) rm -f $(PROGS)

# Even if some jerk creates a file called: 'clean', 'make clean' keeps working.
.PHONY: clean mostlyclean test


# To work without precompiled headers:
# make PCH=no
# or set PCH=no in the environment
ifeq ($(USE_PRECOMPILED_HEADERS),true)

    # Each internal header shall become a precompiled header.
    $(PRECOMPILED_HEADERS): %.$(PCH_EXTENSION): %.$(INTERNAL_HEADER_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

endif


# To work without generated dependencies:
# make DEP=no
# or set DEP=no in the environment
ifeq ($(USE_GENERATED_DEPENDENCIES),true)

    # Use generated dependencies, for header include detection.
    DEPFLAGS = -fpch-deps -MQ $@ -MMD -MP -MF $<.dep
    CXXFLAGS += $(DEPFLAGS)

    # For cleanup and inclusion by Make.
    DEP_FILES = $(patsubst %,%.dep,$(SOURCES) $(INTERNAL_HEADERS))

    # Only include generated dependencies if actually found.
    -include $(DEP_FILES)

endif

# The point of omitting generated dependencies is to reduce remaking when
# (internal) headers are changed. Therefore suppress object remakes on newer
# precompiled headers if not using deps. The alternative is to change generated
# depenencies, but that would require and external tool like sed.
ifeq ($(USE_PRECOMPILED_HEADERS)$(USE_GENERATED_DEPENDENCIES),truetrue)

    # Before compiling any of the objects, rebuild all precompiled headers.
    # (This is a waste when making only one object, but it keeps the Makefile simpler.)
    $(OBJECTS): %.o: $(PRECOMPILED_HEADERS)
# FixMe: When DEP=no, touching an internal header should only lead to re-precompilation of the ih, not to recompilation of the sources.

endif

# Below follow come templates that will create source and header files.
# Only files that don't exist can be created.
# Use like: make bar.hh bar.ih foo.cc

# Don't write escaped newlines. Write normal recipes and escape newlines later.
define NEWLINE


endef


# We use a UUID to keep the header guard unique.
define HEADER_TEMPLATE
#ifndef def_$(UUID)_$(HID)_$(HEADER_EXTENSION)
#define def_$(UUID)_$(HID)_$(HEADER_EXTENSION)
#endif //def_$(UUID)_$(HID)_$(HEADER_EXTENSION)\n
endef


define PROG_TEMPLATE
int main(int argc, char **argv)
try
{
}
catch (...)
{
    return 0;
}
endef


define CXX_TEMPLATE
$(include-internal-headers-in-same-dir)


endef

include-headers-in-same-dir = $(foreach HEADER,$(wildcard $(@D)/*.$(HEADER_EXTENSION)),#include "$(notdir $(HEADER))"\n)
include-internal-headers-in-same-dir = $(foreach IHEADER,$(wildcard $(@D)/*.$(INTERNAL_HEADER_EXTENSION)),#include "$(notdir $(IHEADER))"\n)

define INTERNAL_HEADER_TEMPLATE
$(include-headers-in-same-dir)

using namespace std;\n
endef


NONEXISTENT_GOALS = $(filter-out $(ALL_FILES),$(MAKECMDGOALS))
#$(info nonexistent goals: $(NONEXISTENT_GOALS))
TEMPLATES = $(filter %_TEMPLATE,$(.VARIABLES))
#$(info templates: $(TEMPLATES))
TEMPLATE_TYPES = $(patsubst %_TEMPLATE,%,$(TEMPLATES))
#$(info template types: $(TEMPLATE_TYPES))
TEMPLATABLE_EXTENSIONS = $(foreach TTYPE,$(TEMPLATE_TYPES),$($(TTYPE)_EXTENSION))
#$(info templatable extensions: $(TEMPLATABLE_EXTENSIONS))
TEMPLATABLE_GOALS = $(foreach EXTENSION,$(TEMPLATABLE_EXTENSIONS),$(filter %.$(EXTENSION),$(MAKECMDGOALS)))
#$(info templatable goals: $(TEMPLATABLE_GOALS))

# Templatable goals can be made from a template, and are by definition nonexistent.
ifneq (,$(TEMPLATABLE_GOALS))

    %.cc: TEMPLATE = $(CXX_TEMPLATE)
    %.ih: TEMPLATE = $(INTERNAL_HEADER_TEMPLATE)
    %.hh: TEMPLATE = $(HEADER_TEMPLATE)
    %.hh: UUID := $(subst -,_,$(shell uuid))
    %.hh: HID = $(basename $(notdir $@))

    $(TEMPLATABLE_GOALS):
	printf '$(subst $(NEWLINE),\n,$(TEMPLATE))' >> $@

endif
