#include "cw.ih"

// This function not used anywhere.
int kolibri(int value)
{
    return value / 1000;
}

/*
  The unused function will be compiled.
  And so it ends up in the convenience library too.
  But will not be linked into any executable.
  To verify, try:

    nm --demangle ./ddetect|grep kolibri

 */
