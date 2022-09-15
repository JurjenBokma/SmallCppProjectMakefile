#include "ddetect_utils.hh"
#include <fstream>
#include <limits>
#include <string>

using namespace std;

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
