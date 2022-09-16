#include "ddetect_utils.ih"

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
