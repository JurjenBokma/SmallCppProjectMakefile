#include <fstream>
#include <limits>
#include <string>

enum {
    ERR_SUCCESS = 0,
    ERR_USAGE,
    ERR_NOT_OPEN,
    ERR_NOT_READ,
    ERR_COUNTING_FAIL
};

enum : std::size_t {
    ERR_NOT_COUNTED = std::numeric_limits<std::size_t>::max()
};

std::size_t count_wanted_chars(std::istream &input, std::string const &wanted_chars);

using namespace std;

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
