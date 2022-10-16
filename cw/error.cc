#include "cw.ih"

int error(std::string const &msg, int retval)
{
    cerr << msg;
    return retval;
}

// This function is not used anywhere. (Or so I hope.)
int hippopotamus(int value)
{
    return 10000 * value;
}

/*
  The funcion hippopotamus() is unused, but it will be compiled into the same
  object file as error(). The object is incorporated into the convenience
  library. And whenever a program uses error(), the linker will take the
  entire object, therefore also putting hipopotamus() into the executable.
  This is an important reason why every function should live in a source file
  of its own, which in turn is a reason to use utilities like Make to manage
  the building of a program.
 */
