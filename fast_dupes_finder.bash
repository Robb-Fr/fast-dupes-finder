#!/bin/bash
# finds sizes of all files in directory, sorts them (to make sure duplicates are
# next to each other) and filters to keep only duplicate sizes (size in byte)
duplicated_sizes=$(stat -c%s -- * | sort | uniq -d)
echo "here are the duplicated sizes found: $duplicated_sizes"
# creates a trash folder for found duplicates
mkdir -p trash
# for each size with more than one file having this size
for size in $duplicated_sizes; do
    # read all files in current directory (no recursion to not find in ./trash/
    # , \0 separated for escaping spaces and special characters in file names)
    # with a size of `$size` bytes (hence the `c` parameter)
    while IFS= read -r -d '' file1; do
        # uses basename because find output includes `./`, which breaks cmp
        # and the `find ! -name $file1`
        base1=$(basename "$file1")
        # finds all files that are not `$file1` but have the same size as it
        while IFS= read -r -d '' file2; do
            # checks if both files have identical content (cmp stops at the
            # first byte of difference)
            if cmp -s "$file1" "$file2"; then
                echo "$file2 is a duplicate of $file1"
                # moves the `$file2` to the trash folder and continues
                # evaluating potential duplicates of `$file1`
                mv "$file2" trash
            fi
        done < <(find . ! -name "$base1" -maxdepth 1 -size "$size"c -print0)
    done < <(find . -size "$size"c -maxdepth 1 -print0)
    echo "done one size"
done
