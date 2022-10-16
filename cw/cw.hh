#ifndef def_33b1ce7c_3466_11ed_8f4d_dfa221b644d4_ddetect_utils_hh
#define def_33b1ce7c_3466_11ed_8f4d_dfa221b644d4_ddetect_utils_hh

/// Functions that count wanted chars in streams or files.

#include <istream>
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

using namespace std;

// Display msg, returning retval.
int error(std::string const &msg, int retval);

// Count the number of occurrences of chars from wanted_chars in the input.
// The stream is not repositioned.
std::size_t count_wanted_chars(std::istream &input, std::string const &wanted_chars);

std::size_t count_wanted_chars(std::string const &filename,
                               std::string const &wanted_chars);

void output_count(std::string const &name,
                  size_t count);

int count_from_stdin(string const &wanted_chars);

int count_from_named_files(char const * const *first_filename,
                           size_t nr_files,
                           string const &wanted_chars);


#endif //def_33b1ce7c_3466_11ed_8f4d_dfa221b644d4_ddetect_utils_hh
