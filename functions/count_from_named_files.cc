#include "ddetect_utils.ih"

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
