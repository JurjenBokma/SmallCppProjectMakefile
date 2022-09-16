#include "ddetect_utils.ih"

std::size_t count_wanted_chars(std::string const &filename,
                         std::string const &wanted_chars)
{
    ifstream input(filename);
    if (!input)
        return ERR_COUNTING_FAIL;

    size_t count = count_wanted_chars(input, wanted_chars);
    if (count == ERR_NOT_COUNTED)
        return ERR_COUNTING_FAIL;

    return count;
}
