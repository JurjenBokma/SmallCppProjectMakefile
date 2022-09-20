#include "cw.ih"

int count_from_stdin(string const &wanted_chars)
{
    size_t count = count_wanted_chars(cin, wanted_chars);
    if (count == ERR_NOT_COUNTED)
        return error("Could not count wanted chars on stdin.\n",
                     ERR_COUNTING_FAIL);
    output_count("--: ", count);
    return ERR_SUCCESS;
}
