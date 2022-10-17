# SmallCppProjectMakefile
This Makefile is suitable for building small C++ projects.
It requires very little extra configuration.
It assumes a GNU C++ compiler, and GNU Make:
[Make manual](https://www.gnu.org/software/make/manual/)
It was written for Linux, but has been reported to work on Macs and under
MinGW64. It does not seem to break when make is told to run parallel jobs.

## Most basic use:

Put Makefile and sources in one directory and there issue the command:

    make

To remove all the generated files:

    make clean

## Default behavior:

This Makefile causes `make` to want to build programs, or if there
are no program sources, to build a convenience library. To do so, the
following steps are taken.

* Flexc++ will be called on any scanner specification files.
* Bisonc++ will be called on any parser specification files (grammars).
* C++ source files and internal headers will be preprocessed in order to
  determine their include dependencies.
  [stackoverflow on internal headers](https://stackoverflow.com/questions/11063355/is-anyone-familiar-with-the-implementation-internal-header-ih)
* If included anywhere, C++ internal header files will be precompiled.
* C++ source files will be compiled into object files.
* A convenience library will be composed of all non-program object files.
* Program object files (detected by grepping the source for a `main`
  function) will be linked against the convenience library to become
  executable programs.

## Influencing the Makefile:

The Makefile accepts the usual variables (CXX, CXXFLAGS, CPPFLAGS,
LDFLAGS etc.) as well as FLEXCXX (defaults to: flexc++) and BISONCXX
(defaults to: bisonc++) These can be set in the usual ways:
[How variables get their values](https://www.gnu.org/software/make/manual/html_node/Values.html#Values)

They can also be set in a file `hooks.mk`, which if it exists, will be
included. Extensions can be set there too, though it should seldom be
necessary, as they auto-adapt to files found.

    CXX_SOURCE_EXTENSION (defaults to: cc)
    CXX_HEADER_EXTENSION (defaults to: hh)
    CXX_INTERNAL_HEADER_EXTENSION (defaults to: ih)
    FLEXCXX_SCANNERSPEC_EXTENSION (defaults to: fc++)
    BISONCXX_PARSERSPEC_EXTENSION (defaults to: bc++)

When setting extensions, do NOT include the dot in the extension!
DEPDIR (defaults to: generated_deps) can also be set but is best left alone.

Some variables change the behaviour more extensively:

    VERBOSE=yes causes commands in recipes to be echoed.
    DEP=no      causes dependency analysis to be skipped.
    PCH=no      prevents precompiled headers from being built,
                but not necessarily from being used if they exist.

Note that without analyzing dependencies, Make will not know which
source file includes which internal header, so it will not create or
update precompiled headers.

## Creating files from templates:

Some files can be created from templates integrated in this Makefile.
E.g.:

    mkdir mc
    make mc/myclass.hh
    make mc/myclass.ih
    make mc/ctor1.cc
    mkdir parser
    make parser/grammar.bc++
    make parser/tokenizer.fc++
    make myprog.cc:program

The command for creating a program source differs because it shares its
file extension with non-program sources.
To make header files, the `uuid` utility must be present.
It is convenient to create the header first, because the template for the
internal header will subsequently find and include it. The template for
source files will find the internal header in turn.

## Other files
The other files are just there to demonstrate the purpose of a Makefile.
The .ih-files are internal headers, as explained in comment.
