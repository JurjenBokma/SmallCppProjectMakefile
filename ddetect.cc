/// Program to count chars in files.

#include <fstream>
#include <iostream>
#include <limits>

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

// Display usage info and pass on retval.
int usage(int retval);

// Display msg, returning retval.
int error(std::string const &msg, int retval);

// Count the number of occurrences of chars from wanted_chars in the input.
// The stream is not repositioned.
std::size_t count_wanted_chars(std::istream &input, std::string const &wanted_chars);

std::size_t count_wanted_chars(std::string const &filename,
                               std::string const &wanted_chars);

struct ArgConclusions
{
    bool need_usage;
    string wanted_chars;
    size_t nr_files;
    char const * const * first_filename;
    int exit_code;
};

ArgConclusions handle_arguments(int argc, char **argv);

void output_count(std::string const &name,
                  size_t count);

int count_from_stdin(string const &wanted_chars);

int count_from_named_files(char const * const *first_filename,
                           size_t nr_files,
                           string const &wanted_chars);

int main(int argc, char **argv)
{
    auto const [need_usage,
                wanted_chars,
                nr_files,
                first_filename,
                exit_code]
        = handle_arguments(argc, argv);
    
    if (need_usage)
        return usage(exit_code);

    if (nr_files == 0)
        return count_from_stdin(wanted_chars);

    return count_from_named_files(first_filename,
                                  nr_files,
                                  wanted_chars);
}
