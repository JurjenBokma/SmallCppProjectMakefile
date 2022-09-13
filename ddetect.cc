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

int usage(int retval)
{
    cerr << R"(

        usage: ddetect <chars> [file1 [file2 [...]]]

)";
        return retval;
}

int error(std::string const &msg, int retval)
{
    cerr << msg;
    return retval;
}

std::size_t count_wanted(std::istream &input, std::string const &wanted)
{
    size_t count = 0;
    while (true)
    {
        char ch;
        input.get(ch);
        if (!input)
            break;
        if (wanted.find(ch) != string::npos)
            ++count;
    }
    if (!input.eof())
            return ERR_NOT_COUNTED;
    return count;
}

int main(int argc, char **argv)
{
    if (argc <= 1)
        return usage(ERR_USAGE);
    
    if (argv[1][1] == 'h')
        return usage(ERR_SUCCESS);

    std::string const wanted = argv[1];

    if (argc <= 2) // No further arguments, read from stdin.
    {
        size_t count = count_wanted(cin, wanted);
        if (count == ERR_NOT_COUNTED)
            return error("Could not count wanted chars on stdin.\n",
                         ERR_COUNTING_FAIL);

        cout << "--: " << count << '\n';
    }

    size_t total = 0;

    for (char const * const * arg = argv + 2;
         arg != argv + argc;
         ++arg)
    {
        ifstream input(*arg);
        if (!input)
            return error("Could not open "s +
                         *arg + " for reading.\n",
                         ERR_NOT_OPEN);

        size_t count = count_wanted(input, wanted);
        if (count == ERR_NOT_COUNTED)
            return error("Couldn't count wanted chars in "s +
                         *arg + "\n",
                         ERR_COUNTING_FAIL);

        cout << *arg << ": " << count << '\n';
        total += count;
    }
    if (argc > 3)
        cout << "--------------+\n"
             << "total: " << total << '\n';
}
