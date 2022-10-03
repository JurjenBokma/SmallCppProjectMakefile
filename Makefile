#!/usr/bin/make

# Hand-made Makefile to build small C++ projects.

define HELP_TEXT :=

    This Makefile is suitable for small C++ projects.
    It assumes a GNU C++ compiler, and GNU Make.

    Its most basic uses are:

        make
        make clean

    When this Makefile is used, 'make' wants to build programs, or if there
    are no programs, the convenience library.

    It detects program sources by grepping for a 'main' function, and it
    compiles them into object files. The object files of all other (i.e.
    non-program) sources go into the convenience library.

    The Makefile detects includes, so if a source file includes an internal
    header, the internal header is compiled into a precompiled header before
    the source file is compiled into an object file.

    To finally produce the program, the program object is linked against the
    convenience library.

    The Makefile accepts the usual environment variables, like CXX, CXXFLAGS,
    CPPFLAGS, in the usual ways:
        - exported:

              export CXX=g++-12
              make

        - set on the command line:

              CXXFLAGS=-Wall make

        - or overridden in a command line argument to 'make':

             make CXXFLAGS=-O2

    Additional variables, like CXX_SOURCE_EXTENSION, CXX_HEADER_EXTENSION etc.
    are also used, and can be changed in the same ways.

    Some variables change the behaviour more extensively:

    VERBOSE=yes causes some commands from recipes to be echoed.
    DEP=no      causes dependency analysis to be skipped.
    PCH=no      prevents precompiled headers from being built.

    Note that already-existing dependency files or precompiled headers may
    still get used. So before disabling dependency analysis or precompiled
    headers, a make clean is warranted.

    Also note that without analyzing dependencies, Make will not know which
    source file includes which internal header, so it will not create or
    update precompiled headers.

    This Makefile works with Parallel Make (e.g. make -j4), but the feature is
    not well-tested.

endef

# We recognize files by their extensions, because file magic doesn't always
# work to distinguish C++ from C.

# Extensions can be set here, or in the environment:
# https://www.gnu.org/software/make/manual/html_node/Environment.html#Environment
CXX_SOURCE_EXTENSION ?= cc
# Some use .h
CXX_HEADER_EXTENSION ?= hh
CXX_INTERNAL_HEADER_EXTENSION ?= ih
CXX_PCH_EXTENSION ?= $(CXX_INTERNAL_HEADER_EXTENSION).gch
CXX_OBJECT_EXTENSION ?= $(CXX_SOURCE_EXTENSION).o
DEP_EXTENSION ?= dep

# By default, this Makefile does not echo recipe commands. But it can.
# Try: 'make VERBOSE=1'
VERBOSE ?= false

# We use precompiled headers by default. But they can be turned off.
# Try: make PCH=no
PCH ?= true

# We analyze and heed generated dependencies by default. But they can be
# turned off. Try: make DEP=no
DEP ?= true

# The name of our convenience library.
CONVLIB = libproj.a

# Directory where dependencies are stored.
DEPDIR ?= generated_deps

## No editing below this line unless you know what you're doing. ##

# This Makefile requires GNU Make.
DETECTED_MAKEVERSION = $(shell make --version)
ifneq ($(firstword $(filter GNU,$(DETECTED_MAKEVERSION))),GNU)
    $(error This Makefile requires GNU Make. Detected: $(DETECTED_MAKEVERSION))
endif
undefine DETECTED_MAKEVERSION

# Use any of these words to indicate true or false.
boolalpha = $(or \
   $(if $(filter $(1),t true  True  TRUE  yes Yes YES YESS! on  On  ON  one  One  ONE  1),true,),\
   $(if $(filter $(1),f false False FALSE no  No  NO  NOO!  off Off OFF zero Zero ZERO 0),false,),\
   $(if $(strip $(1)),,false),\
   $(error cannot interpret $(1) as boolean)\
)

# We don't write escaped newlines.
# Write normal recipes and escape newlines later.
define NEWLINE


endef

USE_PRECOMPILED_HEADERS := $(call boolalpha,$(PCH))
undefine PCH

USE_GENERATED_DEPENDENCIES := $(call boolalpha,$(DEP))
undefine DEP

QUIET := $(if $(filter true,$(call boolalpha,$(VERBOSE))),,@)
undefine VERBOSE

# Recursive wildcard to find all files in the current directory and subdirs.
# Using a $(shell find...) would also work, but depend on the find utility.
rwildcard=$(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# Simply list all files we can find.
ALL_FILES := $(patsubst ./%,%,$(call rwildcard,.,*))

deps_of = $(addprefix $(DEPDIR)/,$(addsuffix .$(DEP_EXTENSION),$(1)))

# Anything with a CXX_SOURCE_EXTENSION is a C++ source file.
CXX_SOURCES = $(filter %.$(CXX_SOURCE_EXTENSION),$(ALL_FILES))
# Get object names by replacing the extension.
CXX_OBJECTS = $(CXX_SOURCES:%.$(CXX_SOURCE_EXTENSION)=%.$(CXX_OBJECT_EXTENSION))
CXX_SOURCE_DEPS = $(call deps_of,$(CXX_SOURCES))

# To detect a main() function in a source file.
# Not bulletproof, but KISS.
MAIN_REGEX = int[[:space:]]+main[[:space:]]*\(

# Anything that mentions a main function is a program source.
CXX_PROG_SOURCES := $(shell grep -El '$(MAIN_REGEX)' $(CXX_SOURCES))
CXX_PROG_OBJECTS = $(patsubst %.$(CXX_SOURCE_EXTENSION),%.$(CXX_OBJECT_EXTENSION),$(CXX_PROG_SOURCES))
CXX_PROGS = $(patsubst %.$(CXX_SOURCE_EXTENSION),%,$(CXX_PROG_SOURCES))
CXX_TESTPROGS = $(filter tests/%,$(CXX_PROGS))

# Sources that aren't program sources, are non-program sources.
CXX_NONPROG_SOURCES = $(filter-out $(CXX_PROG_SOURCES),$(CXX_SOURCES))
CXX_NONPROG_OBJECTS = $(patsubst %.$(CXX_SOURCE_EXTENSION),%.$(CXX_OBJECT_EXTENSION),$(CXX_NONPROG_SOURCES))

# From every internal header we can build a precompiled (internal) header.
CXX_INTERNAL_HEADERS = $(filter %.$(CXX_INTERNAL_HEADER_EXTENSION),$(ALL_FILES))

CXX_PRECOMPILED_HEADERS = $(patsubst %,%.gch,$(CXX_INTERNAL_HEADERS))
CXX_PCH_DEPS = $(call deps_of,$(CXX_INTERNAL_HEADERS))

###

# Could be used to suppress all built-in rules.
#.SUFFIXES:

# Suppress making .o from .cc, because we only want to create .cc.o
%.o: %.$(CXX_SOURCE_EXTENSION)

###

# Default target: to make all programs.
all: $(CXX_PROGS) $(CONVLIB)

# Assumption: all programs need the convenience library.
$(CXX_PROGS): $(CONVLIB)

# To create an executable program is called: 'Linking'.
$(CXX_PROGS): ACTION = Linking
$(CXX_PROGS): LDFLAGS += -L. -lproj

$(CXX_OBJECTS): ACTION = Compiling
$(CXX_OBJECTS): CXXFLAGS += -c

$(CONVLIB): ACTION = Collecting

$(CXX_PRECOMPILED_HEADERS): ACTION = Pre-compiling
# When compiling a precompiled header, specify that it's a header.
$(CXX_PRECOMPILED_HEADERS): CXXFLAGS += -x c++-header

# A rule says two things:
# 1. To build any of the target, i.e. $(CONVLIB),
#    we need the prerequisites, i.e. $(CXX_NONPROG_OBJECTS)
# 2. If any of the preprequisites are newer than the target,
#    we need to rebuild the target.
$(CONVLIB): $(CXX_NONPROG_OBJECTS)
	@echo "    [ $(ACTION) $@ <- $^ ]"
	$(QUIET) $(AR) rcs $@ $^
# In the recipe of the rule,
# $@ is the target, i.e. $(CONVLIB)
# $^ is the list of preprequisites, i.e. $(CXX_NONPROG_OBJECTS)

# We don't archive object files member my member, because
# 1. the member is a transient prerequisite that causes remakes,
# 2. allegedly it's slower on large projects,
# 3. the individual archiving actions clutter our output.

# Pattern rule:
# If any program object file is newer than the program itself,
# we rebuild the program, by linking the object file against the convenience library.
$(CXX_PROGS): %: %.$(CXX_OBJECT_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $^ ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

# If the source is newer than its object, we compile it.
$(CXX_OBJECTS): %.$(CXX_OBJECT_EXTENSION): %.$(CXX_SOURCE_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $<

# Clean everything except the programs.
mostlyclean:
	$(QUIET) rm -f $(DEP_FILES) $(CXX_PRECOMPILED_HEADERS) $(CXX_OBJECTS) $(CONVLIB)

# Remove everything Make created.
clean: mostlyclean
	$(QUIET) rm -f $(CXX_PROGS)

# Even if some jerk creates a file called: 'clean', 'make clean' keeps working.
.PHONY: all clean mostlyclean test help

# Don't create unless needed.
.INTERMEDIATE: $(CXX_OBJECTS) $(CXX_PRECOMPILED_HEADERS)

# Once created, don't delete unless by make clean.
.SECONDARY: $(CXX_PRECOMPILED_HEADERS)
#$(CXX_OBJECTS)
# Keep object files around too, to rebuild the library.

help:
	@printf '$(subst $(NEWLINE),\n,$(HELP_TEXT))'


# Below follow come templates that will create source and header files.
# Only files that don't exist can be created.
# Use like: make bar.hh bar.ih foo.cc

# We use a UUID to keep the header guard unique.
define HEADER_TEMPLATE
#ifndef def_$(UUID)_$(HID)_$(CXX_HEADER_EXTENSION)
#define def_$(UUID)_$(HID)_$(CXX_HEADER_EXTENSION)
#endif //def_$(UUID)_$(HID)_$(CXX_HEADER_EXTENSION)\n
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

include-headers-in-same-dir = $(foreach HEADER,$(wildcard $(@D)/*.$(CXX_HEADER_EXTENSION)),#include "$(notdir $(HEADER))"\n)
include-internal-headers-in-same-dir = $(foreach IHEADER,$(wildcard $(@D)/*.$(CXX_INTERNAL_HEADER_EXTENSION)),#include "$(notdir $(IHEADER))"\n)

define INTERNAL_HEADER_TEMPLATE
$(include-headers-in-same-dir)

using namespace std;\n
endef

NONEXISTENT_GOALS = $(filter-out $(ALL_FILES),$(MAKECMDGOALS))
TEMPLATES = $(filter %_TEMPLATE,$(.VARIABLES))
TEMPLATE_TYPES = $(patsubst %_TEMPLATE,%,$(TEMPLATES))
TEMPLATABLE_EXTENSIONS = $(foreach TTYPE,$(TEMPLATE_TYPES),$($(TTYPE)_EXTENSION))
TEMPLATABLE_GOALS = $(foreach EXTENSION,$(TEMPLATABLE_EXTENSIONS),$(filter %.$(EXTENSION),$(MAKECMDGOALS)))

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

# Generated dependencies are enabled by default. To suppress: make DEP=no
ifeq ($(USE_GENERATED_DEPENDENCIES),true)

    # Make can be told to include generated dependency files.
    # But it cannot be told to include such dependencies only for sources that
    # actually must be compiled. So we simply always include all dependencies.
    # (With C++ Modules, we'll need to anyway.)

    # Prevent dependency generation if MAKECMDGOALS is non-empty and consists
    # only of targets that don't need dependencies.
    TARGETS_THAT_DONT_NEED_DEPS := clean mostlyclean depclean help
    MAKECMDGOALS_IS_EMPTY := $(if $(MAKECMDGOALS),,yes)
    GOALS_THAT_NEED_DEPS := $(strip $(filter-out $(TARGETS_THAT_DONT_NEED_DEPS),$(MAKECMDGOALS)))
    NEED_DEP_INCLUDES := $(or $(MAKECMDGOALS_IS_EMPTY),$(GOALS_THAT_NEED_DEPS))

    # When only cleaning, we don't need dependencies.
    ifneq (,$(NEED_DEP_INCLUDES))
        include $(CXX_SOURCE_DEPS) $(CXX_PCH_DEPS)
    endif

    undefine TARGETS_THAT_DONT_NEED_DEPS
    undefine MAKECMDGOALS_IS_EMPTY
    undefine GOALS_THAT_NEED_DEPS
    undefine NEED_DEP_INCLUDES

    $(CXX_SOURCE_DEPS) $(CXX_PCH_DEPS): ACTION = Analyzing dependencies
    # These are flags for generating dependencies.
    $(CXX_SOURCE_DEPS): CPPFLAGS += -E -fdirectives-only -MQ $(patsubst %.$(CXX_SOURCE_EXTENSION),%.$(CXX_OBJECT_EXTENSION),$<) -MM -MF $@
    $(CXX_PCH_DEPS): CPPFLAGS += -E -fdirectives-only -MQ $(patsubst %.$(CXX_INTERNAL_HEADER_EXTENSION),%.$(CXX_PCH_EXTENSION),$<) -MM -MF $@
    $(CXX_PCH_DEPS): CXXFLAGS += -x c++-header

    # Meaning:
    #-MQ $@: Change target of rule.
    #-MM:    Output dependencies, not preprocessor output. Implies -E.
    #-MF Specify file to write dependencies to.

    # To create a .dep file from a source or internal header file.
    $(CXX_SOURCE_DEPS) $(CXX_PCH_DEPS): $(DEPDIR)/%.$(DEP_EXTENSION): %
	@mkdir -p $(dir $@)
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) $<
    # If dependency generation should not be silent, add this command to the recipe:
    #	@echo "    [ $(ACTION) $@ <- $< ]"

    # Keep deps once we have them.
    .SECONDARY: $(CXX_SOURCE_DEPS) $(CXX_PCH_DEPS)

    # When cleaning, we should get rid of the deps again.
    clean: depclean
    depclean:
	$(QUIET) rm -rf $(DEPDIR)

    .PHONY: depclean

endif

### Some measures to help Parallel Make ( make --jobs n) ###

# Make does not canonicalize relative paths in generated dependencies. As a
# result it may want to make foo/../bar.ih.gch,
# which can when simplified reads:  bar.ih.gch.
# With Parallel Make this is more often a problem.
# To mitigate, we tell Make how to remove the /../ from paths:
define PATH_STRAIGHTENING_RECIPE
$(DIR)../%: $(patsubst ./%,%,$(dir $(DIR:%/=%))%)
	@echo "    [ Substituting \"$$<\" <- \"$$@\": same file by straightened path. ]"
endef

# Evaluating the paths straightening recipe for all available dirs.
DIRECTORIES_FOUND = $(sort $(filter-out ./,$(dir $(ALL_FILES:./%=%))))
#$(foreach DIR,$(DIRECTORIES_FOUND), $(info $(PATH_STRAIGHTENING_RECIPE)))
$(foreach DIR,$(DIRECTORIES_FOUND), $(eval $(PATH_STRAIGHTENING_RECIPE)))

### End of Parallel Make measures. ###

# Postpone double expansion to as late as possible.
.SECONDEXPANSION:

# To work without precompiled headers:
# make PCH=no
# or set PCH=no in the environment
ifeq ($(USE_PRECOMPILED_HEADERS),true)

    # Each internal header shall become a precompiled header.
    $(CXX_PRECOMPILED_HEADERS): %.$(CXX_PCH_EXTENSION): %.$(CXX_INTERNAL_HEADER_EXTENSION)
	@echo "    [ $(ACTION) $@ <- $< ]"
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

    # For each internal header in the dependencies, add a precompiled header.
    # (Leaving the internal header in is simpler and doesn't hurt.)
    $(CXX_OBJECTS): $$(patsubst %.$(CXX_INTERNAL_HEADER_EXTENSION),%.$(CXX_PCH_EXTENSION),$$^)

endif
