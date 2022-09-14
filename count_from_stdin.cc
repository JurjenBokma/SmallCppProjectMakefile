#include <iostream>
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

int error(std::string const &msg, int retval);
std::size_t count_wanted_chars(std::istream &input, std::string const &wanted_chars);
void output_count(std::string const &name, size_t count);


using namespace std;

int count_from_stdin(string const &wanted_chars)
{
    size_t count = count_wanted_chars(cin, wanted_chars);
    if (count == ERR_NOT_COUNTED)
        return error("Could not count wanted chars on stdin.\n",
                     ERR_COUNTING_FAIL);
    output_count("--: ", count);
    return ERR_SUCCESS;
}
