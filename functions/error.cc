#include "ddetect_utils.ih"

int error(std::string const &msg, int retval)
{
    cerr << msg;
    return retval;
}

// This function is not used anywhere. (Or so I hope.)
int hippopotamus(int value)
{
    return 1000 * value;
}
