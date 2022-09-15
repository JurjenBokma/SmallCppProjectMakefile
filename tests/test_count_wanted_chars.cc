#include <iostream>
#include <limits>
#include <sstream>

enum : bool
{
    FAILURE = false,
    SUCCESS = true
};

enum : std::size_t {
    ERR_NOT_COUNTED = std::numeric_limits<std::size_t>::max()
};

using namespace std;

std::size_t count_wanted_chars(std::istream &input, std::string const &wanted_chars);


int main()
{
    istringstream test_input("This is a journey into C++!\n");
    return
        count_wanted_chars(test_input, "aeiou") == 9 ? SUCCESS : FAILURE;
}
