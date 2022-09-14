#include <string>

using namespace std;

enum {
    ERR_SUCCESS = 0,
    ERR_USAGE,
    ERR_NOT_OPEN,
    ERR_NOT_READ,
    ERR_COUNTING_FAIL
};

struct ArgConclusions
{
    bool need_usage;
    string wanted_chars;
    size_t nr_files;
    char const * const * first_filename;
    int exit_code;
};

ArgConclusions handle_arguments(int argc, char **argv)
{
    if (argc <= 1)
        return {true, "", 0, nullptr, ERR_USAGE};

    if ("-h"s == argv[1])
        return {true, "", 0, nullptr, ERR_SUCCESS};

    return {
        false,
        argv[1],
        static_cast<size_t>(argc - 2),
        argv + 2,
        ERR_SUCCESS
    };
}
