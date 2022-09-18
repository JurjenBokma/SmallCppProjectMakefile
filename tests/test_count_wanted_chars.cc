#include "../project.ih"

enum
{
    SUCCESS = 0,
    FAILURE
};

int main()
{
    std::string const text = "This is a journey into C++!";

    istringstream test_input(text);
    size_t const counted = count_wanted_chars(test_input, "aeiou");
    
    if (counted == 8)
        return SUCCESS;
    cerr << "Error in count_wanted_chars:\n"
        "We expected nine vowels (not counting the 'y')"
        " in the text \"" << text << "\", but found " << counted << '\n';
    return FAILURE;
}
