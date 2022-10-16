#!/usr/bin/make

define HELP_TEXT =

    This Makefile is suitable for small C++ projects.
    It assumes a GNU C++ compiler, and GNU Make.

    # Most basic use:

        make
        make clean

    # Default behavior:

    This Makefile tells 'make' to wants to build programs, or if there
    are no programs, the convenience library.

    Flexc++ will be called on any scanner specification files.
    Bisonc++ will be called on any parser specification files (grammars).
    C++ internal header files will be precompiled.
    C++ source files will be compiled into object files.
    Program objects (detected by grepping the source for a 'main' function)
    will be linked against the convenience library, which will be composed of
    all other object files.

    # Influencing the working of the Makefile:

    The Makefile accepts the usual variables (CXX, CXXFLAGS, CPPFLAGS,
    LDFLAGS etc.)

    These can be set in the usual ways: as exported environment variables,
    set on the command line as shell variables (before the command) or as
    overriding parameters to Make (after the command):

              export CXX=g++-12
              CXX=g++-12 make
              make CXX=g++-12

    This is suitable for ad-hoc settings.
    Permanent settings for a project can be put in a file hooks.mk, which if
    present will be included in the Makefile. That is a suitable place to
    specify e.g.

    CXX_SOURCE_EXTENSION (defaults to: $(CXX_SOURCE_EXTENSION))
    CXX_HEADER_EXTENSION (defaults to: $(CXX_HEADER_EXTENSION))
    CXX_INTERNAL_HEADER_EXTENSION (defaults to: $(CXX_INTERNAL_HEADER_EXTENSION))
    CXX_PCH_EXTENSION (defaults to: $(CXX_PCH_EXTENSION))
    CXX_OBJECT_EXTENSION (defaults to: $(CXX_OBJECT_EXTENSION))
    DEP_EXTENSION (defaults to: $(DEP_EXTENSION))
    FLEXCXX_SCANNERSPEC_EXTENSION (defaults to: $(FLEXCXX_SCANNERSPEC_EXTENSION))
    BISONCXX_PARSERSPEC_EXTENSION (defaults to: $(BISONCXX_PARSERSPEC_EXTENSION))
    DEPDIR (defaults to: $(DEPDIR))
    FLEXCXX (defaults to: $(FLEXCXX))
    BISONCXX (defaults to: $(BISONCXX))

    When setting these, do NOT include the dot in the extension!
    Read the actual Makefile to find out what else to set.

    Some variables change the behaviour more extensively:

        VERBOSE=yes causes some commands from recipes to be echoed.
        DEP=no      causes dependency analysis to be skipped.
        PCH=no      prevents precompiled headers from being built.

    Already-existing dependency files or precompiled headers may still get
    used. So before disabling dependency analysis or precompiled headers, a
    make clean is warranted.

    Also note that without analyzing dependencies, Make will not know which
    source file includes which internal header, so it will not create or
    update precompiled headers.

    This Makefile works with Parallel Make (e.g. make -j4), but the feature is
    not well-tested.

    It can also create header, internal header and source files, preferably in
    that order, from templates. E.g.:

        mkdir mc
        make mc/mc.hh
        make mc/mc.ih
        make mc/ctor1.cc

    Flexc++ scanner specifications and bisonc++ parser specifications can also
    be generated from templates.
    For making programs from template, the syntax is a bit different, as they
    share their extension with ordinary source files. To make myprog.cc, say:

        make myprog.cc:program


endef

# The file hooks.mk will be included if it exists.
# You could put project-specific settings there.
-include hooks.mk

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

FLEXCXX_SCANNERSPEC_EXTENSION ?= fc++
BISONCXX_PARSERSPEC_EXTENSION ?= bc++

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
CONVLIB = $(notdir $(CURDIR))
CONVLIB_FILE = lib$(CONVLIB).a

# Directory where dependencies are stored.
DEPDIR ?= generated_deps

FLEXCXX ?= flexc++
BISONCXX ?= bisonc++

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
CXX_SOURCES := $(filter %.$(CXX_SOURCE_EXTENSION),$(ALL_FILES))

# Get object names by replacing the extension.
CXX_OBJECTS := $(CXX_SOURCES:%.$(CXX_SOURCE_EXTENSION)=%.$(CXX_OBJECT_EXTENSION))
CXX_SOURCE_DEPS := $(call deps_of,$(CXX_SOURCES))

# To detect a main() function in a source file.
# Not bulletproof, but KISS.
MAIN_REGEX := int[[:space:]]+main[[:space:]]*\(

# Anything that mentions a main function is a program source.
CXX_PROG_SOURCES := $(shell grep -El '$(MAIN_REGEX)' $(CXX_SOURCES))
CXX_PROG_OBJECTS := $(patsubst %.$(CXX_SOURCE_EXTENSION),%.$(CXX_OBJECT_EXTENSION),$(CXX_PROG_SOURCES))
CXX_PROGS := $(CXX_PROG_SOURCES:%.$(CXX_SOURCE_EXTENSION)=%)
CXX_TESTPROGS := $(filter tests/%,$(CXX_PROGS))

# Sources that aren't program sources, are non-program sources.
CXX_NONPROG_SOURCES := $(filter-out $(CXX_PROG_SOURCES),$(CXX_SOURCES))
CXX_NONPROG_OBJECTS := $(CXX_NONPROG_SOURCES:%.$(CXX_SOURCE_EXTENSION)=%.$(CXX_OBJECT_EXTENSION))

# From every internal header we can build a precompiled (internal) header.
CXX_INTERNAL_HEADERS := $(filter %.$(CXX_INTERNAL_HEADER_EXTENSION),$(ALL_FILES))

CXX_PRECOMPILED_HEADERS := $(CXX_INTERNAL_HEADERS:%=%.gch)
CXX_PCH_DEPS := $(call deps_of,$(CXX_INTERNAL_HEADERS))

FLEXCXX_SCANNERSPECS := $(filter %.$(FLEXCXX_SCANNERSPEC_EXTENSION),$(ALL_FILES))
FLEXCXX_DEPS := $(call deps_of,$(FLEXCXX_SCANNERSPECS))

BISONCXX_PARSERSPECS := $(filter %.$(BISONCXX_PARSERSPEC_EXTENSION),$(ALL_FILES))
BISONCXX_DEPS := $(call deps_of,$(BISONCXX_PARSERSPECS))

###

# Could be used to suppress all built-in rules.
.SUFFIXES:

# Suppress making .o from .cc, because we only want to create .cc.o
%.o: %.$(CXX_SOURCE_EXTENSION)

###

# Default target: to make all programs, or at least the convenience library.
all: $(CXX_PROGS) $(CONVLIB_FILE)

# Assumption: all programs need the convenience library.
$(CXX_PROGS): $(CONVLIB_FILE)

# To create an executable program is called: 'Linking'.
$(CXX_PROGS): ACTION = Linking
$(CXX_PROGS): LDFLAGS += -L. -l$(CONVLIB)

$(CXX_OBJECTS): ACTION = Compiling
$(CXX_OBJECTS): INPUTS = $(filter %.$(CXX_SOURCE_EXTENSION),$^)
$(CXX_OBJECTS): CXXFLAGS += -c

$(CONVLIB_FILE): ACTION = Collecting

$(CXX_PRECOMPILED_HEADERS): ACTION = Pre-compiling
$(CXX_PRECOMPILED_HEADERS): INPUTS = $(filter %.$(CXX_INTERNAL_HEADER_EXTENSION),$^)

# When compiling a precompiled header, specify that it's a header.
$(CXX_PRECOMPILED_HEADERS): CXXFLAGS += -x c++-header

ECHO_ACTION = @echo "    [ $(ACTION) $(or $(TARGET),$@) <- $(or $(INPUTS),$^) ]"

# A rule says two things:
# 1. To build any of the target, i.e. $(CONVLIB_FILE),
#    we need the prerequisites, i.e. $(CXX_NONPROG_OBJECTS)
# 2. If any of the preprequisites are newer than the target,
#    we need to rebuild the target.
$(CONVLIB_FILE): $(CXX_NONPROG_OBJECTS)
	$(ECHO_ACTION)
	$(QUIET) $(AR) rcs $@ $^
# In the recipe of the rule,
# $@ is the target, i.e. $(CONVLIB_FILE)
# $^ is the list of preprequisites, i.e. $(CXX_NONPROG_OBJECTS)

# We don't archive object files member my member, because
# 1. the member is a transient prerequisite that causes remakes,
# 2. allegedly it's slower on large projects,
# 3. the individual archiving actions clutter our output.

# If any program object file is newer than the program itself,
# we rebuild the program, by linking the object file against the convenience library.
$(CXX_PROGS): %: %.$(CXX_OBJECT_EXTENSION)
	$(ECHO_ACTION)
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $< $(LDFLAGS)

# If the source is newer than its object, we compile it.
$(CXX_OBJECTS): %.$(CXX_OBJECT_EXTENSION): %.$(CXX_SOURCE_EXTENSION)
	$(ECHO_ACTION)
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -o $@ $<

# Clean everything except the programs.
mostlyclean:
	$(QUIET) rm -f $(DEP_FILES) $(CXX_PRECOMPILED_HEADERS) $(CXX_OBJECTS) $(CONVLIB_FILE)

# Remove everything Make created.
clean: mostlyclean
	$(QUIET) rm -f $(CXX_PROGS)

# Even if some jerk creates a file called: 'clean', 'make clean' keeps working.
.PHONY: all clean mostlyclean test help

# Don't create unless needed:
.INTERMEDIATE: $(CXX_OBJECTS) $(CXX_PRECOMPILED_HEADERS)

# Once created, don't delete unless by make clean.
.SECONDARY: $(CXX_PRECOMPILED_HEADERS) $(CXX_OBJECTS)

help:
	@printf '$(subst $(NEWLINE),\n,$(HELP_TEXT))'

# Give Make no way to make hooks.mk. User has to create it.
hooks.mk:


# Making files from template is nice, but we can't safely tell Make to just
# create any source file from scratch. There are too many cases where it may
# need a file foo.bar, and decide that it can make one if it has foo.bar.cc,
# so create that first.
# So we only enable templates for files that don't exist yet.

# The program source template shares its suffix with other sources.
# So we use this trick: make foo.cc:program will create a program.
ACTUAL_FILE = $(addsuffix .$(EXTENSION),$(patsubst %.$(EXTENSION),%,$*))

%\:program: TEMPLATE = $(CXX_PROGRAM_TEMPLATE)
%\:program: EXTENSION = $(CXX_SOURCE_EXTENSION)

%\:program:
	$(QUIET) if test -e "$(ACTUAL_FILE)" ; then echo "$(ACTUAL_FILE) already exists." ; false ; fi
	$(QUIET) printf '$(subst $(NEWLINE),\n,$(TEMPLATE))' >> "$(ACTUAL_FILE)" && echo "$(ACTUAL_FILE) made from template"

%\:cxx_class: %\:cxx_header %\:cxx_internal_header

###  Below follow some templates that will create source and header files. ###

# Only files that are explictly mentioned on the command line and that don't
#exist yet, can be created. Use like: make bar.hh


# Header template. We use a UUID to keep the header guard unique.
define CXX_HEADER_TEMPLATE
#ifndef def_$(UUID)_$(HID)_$(CXX_HEADER_EXTENSION)
#define def_$(UUID)_$(HID)_$(CXX_HEADER_EXTENSION)
#endif //def_$(UUID)_$(HID)_$(CXX_HEADER_EXTENSION)\n
endef


# To detect (internal) headers that already exist in the dir.
include-headers-in-same-dir = $(foreach HEADER,$(wildcard $(@D)/*.$(CXX_HEADER_EXTENSION)),#include "$(notdir $(HEADER))"\n)
include-internal-headers-in-same-dir = $(foreach IHEADER,$(wildcard $(@D)/*.$(CXX_INTERNAL_HEADER_EXTENSION)),#include "$(notdir $(IHEADER))"\n)


define CXX_INTERNAL_HEADER_TEMPLATE
$(include-headers-in-same-dir)

using namespace std;\n
endef


define CXX_SOURCE_TEMPLATE
$(include-internal-headers-in-same-dir)


endef

define CXX_PROGRAM_TEMPLATE
int main(int argc, char **argv)
try
{
}
catch (...)
{
    return 0;
}
endef

define FLEXCXX_SCANNERSPEC_TEMPLATE

//%%baseclass-header = "filename"
//%%case-insensitive
//%%class-header = "filename"
//%%class-name = "className"
//%%debug
//%%filenames = "basename"
//%%implementation-header = "filename"
//%%input-implementation = "sourcefile"
//%%input-interface = "interface"
//%%interactive
//%%lex-function-name = "funname"
//%%lex-source = "filename"
//%%no-lines
//%%namespace = "identifer"
//%%print-tokens
//%%s start-conditions
//%%skeleton-directory = "pathname"
//%%startcondition-name = "startconditionName"
//%%target-directory = "pathname"
//%%x miniscanners

%%%%

.|\\n   return 0x100;

endef

define BISONCXX_PARSERSPEC_TEMPLATE
//  With multiple parsers in one project, give each one its own namespace.
// %%namespace pns

// %%baseclass-preinclude: specifying a header included by the baseclass
// %%class-name: defining the name of the parser class
// %%debug: adding debugging code to the parse() member

//  Flexc++-generated default. Adjust to needs.
%%scanner Scanner.h

// %%baseclass-header: defining the parser base class header
// %%class-header: defining the parser class header
// %%filenames: specifying a generic filename
// %%implementation-header: defining the implementation header
// %%parsefun-source: defining the parse() function sourcefile
// %%target-directory: defining the directory where files must be written
// %%token-path: defining the path of the file containing the Tokens_ enumeration

// %%polymorphic INT: int; STRING: std::string; 
//               VECT: std::vector<double>

%%token TERMINAL

%%%%

nonterminal:
TERMINAL
;

endef

# Giving Make a recipe to create any file 'foo.cc' from thin air is dangerous,
# because it would do so whenever it needs a file 'foo'. So we allow it to
# create only files that are explicitly mentioned on the command line, and
# then only if they don't exist yet.
NONEXISTENT_GOALS = $(filter-out $(ALL_FILES),$(MAKECMDGOALS))
TEMPLATES = $(filter %_TEMPLATE,$(.VARIABLES))
TEMPLATE_TYPES = $(patsubst %_TEMPLATE,%,$(TEMPLATES))
TEMPLATABLE_EXTENSIONS = $(foreach TTYPE,$(TEMPLATE_TYPES),$($(TTYPE)_EXTENSION))
TEMPLATABLE_GOALS = $(foreach EXTENSION,$(TEMPLATABLE_EXTENSIONS),$(filter %.$(EXTENSION),$(MAKECMDGOALS)))

# Templatable goals can be made from a template, and are by definition nonexistent.
ifneq (,$(TEMPLATABLE_GOALS))

    %.$(CXX_SOURCE_EXTENSION): TEMPLATE = $(CXX_SOURCE_TEMPLATE)
    %.$(CXX_INTERNAL_HEADER_EXTENSION): TEMPLATE = $(CXX_INTERNAL_HEADER_TEMPLATE)
    %.$(CXX_HEADER_EXTENSION): TEMPLATE = $(CXX_HEADER_TEMPLATE)
    %.$(CXX_HEADER_EXTENSION): UUID := $(subst -,_,$(shell uuid))
    %.$(CXX_HEADER_EXTENSION): HID = $(basename $(notdir $@))
    %.$(FLEXCXX_SCANNERSPEC_EXTENSION): TEMPLATE = $(FLEXCXX_SCANNERSPEC_TEMPLATE)
    %.$(BISONCXX_PARSERSPEC_EXTENSION): TEMPLATE = $(BISONCXX_PARSERSPEC_TEMPLATE)

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
    TARGETS_THAT_DONT_NEED_DEPS := clean mostlyclean depclean help $(TEMPLATABLE_GOALS)
    MAKECMDGOALS_IS_EMPTY := $(if $(MAKECMDGOALS),,yes)
    GOALS_THAT_NEED_DEPS := $(strip $(filter-out $(TARGETS_THAT_DONT_NEED_DEPS),$(MAKECMDGOALS)))
    NEED_DEP_INCLUDES := $(or $(MAKECMDGOALS_IS_EMPTY),$(GOALS_THAT_NEED_DEPS))

    # When only cleaning, we don't need dependencies.
    ifneq (,$(NEED_DEP_INCLUDES))
        include $(CXX_SOURCE_DEPS) $(CXX_PCH_DEPS) $(FLEXCXX_DEPS) $(BISONCXX_DEPS)
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
	$(QUIET) mkdir -p $(dir $@)
	$(ECHO_ACTION)
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) $<
    # If dependency generation should not be silent, add this command to the recipe:
    #@echo "    [ $(ACTION) $@ <- $< ]"

    # Figuring out flexc++' output from a given scannerspec is hard. So we simply
    # keep a touchfile and rerun flexc++ whenever the spec is newer.
    # We use --target-directory to put generated files in the same dir as the spec
    # they were generated from. That won't work on specs that have internal
    # %target-directory directives. FixMe?
    $(FLEXCXX_DEPS): ACTION = Running $(FLEXCXX) merely to update empty timestamp:
    $(FLEXCXX_DEPS): $(DEPDIR)/%.$(DEP_EXTENSION): %
	$(ECHO_ACTION)
	$(QUIET) $(FLEXCXX) $(FLEXCXXFLAGS) $(if $(*D),--target-directory='$(*D)') $< 
	$(QUIET) mkdir -p $(dir $@)
	$(QUIET) touch $@

    # In contrast to flexc++, bisonc++ puts the generated files in the
    # directory of the parser specification by default. No options needed.
    $(BISONCXX_DEPS): ACTION = Running $(BISONCXX) merely to update empty timestamp:
    $(BISONCXX_DEPS): $(DEPDIR)/%.$(DEP_EXTENSION): %
	$(ECHO_ACTION)
	$(QUIET) $(BISONCXX) $(BISONCXXFLAGS) $< 
	$(QUIET) mkdir -p $(dir $@)
	$(QUIET) touch $@

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
# which when simplified reads:      bar.ih.gch.
# With Parallel Make this more often turns out to be a problem.
# To mitigate, we tell Make how to remove the /../ from paths:
define PATH_STRAIGHTENING_RECIPE
$(DIR)../%: $(patsubst ./%,%,$(dir $(DIR:%/=%))%)
	@echo "    [ Substituting \"$$<\" <- \"$$@\": same file by straightened path. ]"
endef

# Evaluating the path straightening recipe for all available dirs.
DIRECTORIES_FOUND = $(sort $(filter-out ./,$(dir $(ALL_FILES:./%=%))))
$(foreach DIR,$(DIRECTORIES_FOUND), $(eval $(PATH_STRAIGHTENING_RECIPE)))
#$(foreach DIR,$(DIRECTORIES_FOUND), $(info $(PATH_STRAIGHTENING_RECIPE)))


### Checking for include guards ###

CXX_HEADERS := $(filter %.$(CXX_HEADER_EXTENSION),$(ALL_FILES))

include-guard-checks: $(CXX_HEADERS)
	~/dev/bash/double-include-check $^

.PHONY: include-guard-checks

### End of include guard check ###


### End of Parallel Make measures. ###

# Postpone double expansion to as late as possible.
.SECONDEXPANSION:

# To work without precompiled headers:
# make PCH=no
ifeq ($(USE_PRECOMPILED_HEADERS),true)

    # Each internal header shall become a precompiled header.
    $(CXX_PRECOMPILED_HEADERS): %.$(CXX_PCH_EXTENSION): %.$(CXX_INTERNAL_HEADER_EXTENSION)
	$(ECHO_ACTION)
	$(QUIET) $(CXX) $(CPPFLAGS) $(CXXFLAGS) -c -o $@ $<

    # For each internal header in the prerequisites, add a precompiled header.
    # (Leaving the internal header in is simpler and doesn't hurt.)
    $(CXX_OBJECTS): $$(patsubst %.$(CXX_INTERNAL_HEADER_EXTENSION),%.$(CXX_PCH_EXTENSION),$$^)

endif
