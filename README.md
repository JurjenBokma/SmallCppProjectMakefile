# SmallCppProjectMakefile
This Makefile will build small C++ projects on Linux

* It assumes Linux, Bash, and GNU g++, as well as the presence of grep.
* It's tailored to using project-internal headers. These will be precompiled.
* It detects include dependencies, so when a header file changes, all sources
  that include it will be recompiled.
* It can handle flexc++ and bisonc++ input files.

Although very little testing has been done, it has been reported to also work
with parallel Make, as well as on MacOSX, and to some extent even under
MinGW64.

## Other files
The other files are just there to demonstrate the purpose of a Makefile.
The .ih-files are internal headers.

## Help
Use:

   make help
