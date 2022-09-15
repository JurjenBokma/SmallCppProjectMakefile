/// Program to count chars in files.

#include "ddetect_utils.hh"


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
