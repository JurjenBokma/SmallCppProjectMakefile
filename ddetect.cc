/// Program to count chars in files.

#include <fstream>
#include <iostream>

enum {
    ERR_SUCCESS = 0,
    ERR_USAGE,
    ERR_NOT_OPEN,
    ERR_NOT_READ,
};

using namespace std;

int main(int argc, char **argv)
{
    if (argc <= 1)
    {
        cerr << R"(

        usage: ddetect <chars> [file1 [file2 [...]]]

)";
        return ERR_USAGE;
    }
    if (argv[1][1] == 'h')
    {
        cerr << R"(

        usage: ddetect <chars> [file1 [file2 [...]]]

)";
        return ERR_SUCCESS;
    }

    std::string const wanted = argv[1];

    if (argc <= 2) // No further arguments, read from stdin.
    {
        size_t count = 0;
        while (true)
        {
            char ch;
            cin.get(ch);
            if (!cin)
                break;
            if (wanted.find(ch) != string::npos)
                ++count;
        }
        if (!cin.eof())
        {
            cerr << "Error reading from stdin\n";
            return ERR_NOT_READ;
        }
        cout << "--: " << count << '\n';
    }

    size_t total = 0;

    for (char const * const * arg = argv + 2;
         arg != argv + argc;
         ++arg)
    {
        ifstream input(*arg);
        if (!input)
        {
            cerr << "Could not open "
                 << *arg << " for reading.\n";
            return ERR_NOT_OPEN;
        }
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
        {
            cerr << "Error reading " << *arg  << "\n";
            return ERR_NOT_READ;
        }
        cout << *arg << ": " << count << '\n';
        total += count;
    }
    if (argc > 3)
        cout << "--------------+\n"
             << "total: " << total << '\n';
}
