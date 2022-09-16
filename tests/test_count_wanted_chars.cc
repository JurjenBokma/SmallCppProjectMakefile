#include "../project.ih"

enum
{
    SUCCESS = 0,
    FAILURE
};

int main()
{
    istringstream test_input("This is a journey into C++!\n");
    return
        count_wanted_chars(test_input, "aeiou") == 9 ? SUCCESS : FAILURE;
}
