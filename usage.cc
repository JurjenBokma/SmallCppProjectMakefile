#include "ddetect_utils.hh"
#include <iostream>

using namespace std;

int usage(int retval)
{
    cerr << R"(

        usage: ddetect <chars> [file1 [file2 [...]]]

)";
        return retval;
}