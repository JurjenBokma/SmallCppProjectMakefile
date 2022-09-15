#include "ddetect_utils.hh"
#include <iostream>
#include <string>

using namespace std;

int error(std::string const &msg, int retval)
{
    cerr << msg;
    return retval;
}
