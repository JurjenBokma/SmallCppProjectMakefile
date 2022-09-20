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
