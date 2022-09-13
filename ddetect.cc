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
int usage(int retval)
{
    cerr << R"(

        usage: ddetect <chars> [file1 [file2 [...]]]

)";
        return retval;
}

// Display msg, returning retval.
int error(std::string const &msg, int retval)
{
    cerr << msg;
    return retval;
}

// Count the number of occurrences of chars from wanted_chars in the input.
// The stream is not repositioned.
std::size_t count_wanted_chars(std::istream &input, std::string const &wanted_chars)
{
    size_t count = 0;
    
    while (true)
    {
        char ch;
        input.get(ch);
        if (!input)
            break;
        if (wanted_chars.find(ch) != string::npos)
            ++count;
    }
    
    if (!input.eof())
            return ERR_NOT_COUNTED;
    return count;
}

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

void output_count(std::string const &name,
                          size_t count)
{
    cout << name << ": " << count << '\n';
}

int count_from_stdin(string const &wanted_chars)
{
    size_t count = count_wanted_chars(cin, wanted_chars);
    if (count == ERR_NOT_COUNTED)
        return error("Could not count wanted chars on stdin.\n",
                     ERR_COUNTING_FAIL);
    output_count("--: ", count);
    return ERR_SUCCESS;
}

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
