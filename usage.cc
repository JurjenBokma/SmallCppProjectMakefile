#include "project.ih"

int usage(int retval)
{
    cerr << R"(

        usage: ddetect <chars> [file1 [file2 [...]]]

)";
        return retval;
}
