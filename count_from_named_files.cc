#include <limits>
#include <string>
#include <istream>

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
std::size_t count_wanted_chars(std::string const &filename,
                               std::string const &wanted_chars);
void output_count(std::string const &name, size_t count);

using namespace std;

int count_from_named_files(char const * const *first_filename,
                           size_t nr_files,
                           string const &wanted_chars)
{
    size_t total = 0;

    for (char const * const * filename = first_filename;
         filename != first_filename + nr_files;
         ++filename)
        if (size_t count = count_wanted_chars(*filename, wanted_chars);
            count == ERR_NOT_COUNTED)
            return error("Failed to count "s + *filename,
                         ERR_COUNTING_FAIL);
        else
        {
            output_count(*filename, count);
            total += count;
        }
    
    if (nr_files > 1)
        output_count("--------------+\ntotal", total);
    
    return ERR_SUCCESS;
}
