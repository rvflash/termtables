#!/bin/awk -f

##
# Aggregate a CSV file and expose the COUNT, SUM and DISTINCT methods
# @param int omitHeader If 1, exclude the first line
# @param string header New header line
# @param string distinctColumns List of columns by index to use in single mode
# @param string countColumns List of columns by index to count, separated by space
# @param string sumColumns List of columns by index to sum, separated by space
# @param string groupByColumns List of columns by index to use to group, separated by space
#
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/shcsv

BEGIN {
    # Skip header line
    start=1;
    if (1 == omitHeader) {
        start++;
    }

    # Manage empty input file
    aggregating[""]="";
    count[""]=0;
    distinct[""]=0;
    sum[""]=0;

    # Convert string args to array
    split(distinctColumns, distincts, " ");
    split(countColumns, counts, " ");
    split(sumColumns, sums, " ");
    split(groupByColumns, groups, " ");
}
(NR >= start) {
    # Group by (single or multiple columns)
    group="";
    for (column in groups) {
        if ("" == group) {
            group=$groups[column];
        } else {
            group=group FS $groups[column];
        }
    }

    # Distinct (if no group has been defined but first column requested as distinct value, use it as group)
    if ("" == group && inArray(1, distincts)) {
        group=$1;
    }
    aggregating[group]=$0;

    # Count
    count[group]++;
    for (column in counts) {
        if (inArray(counts[column], distincts)) {
            distinct[counts[column] FS group FS $counts[column]]++;
        }
    }

    # Sum
    for (column in sums) {
        sum[sums[column] FS group]+=$sums[column];
    }
}
END {
    # Output the new header line
    if ("" != header) {
        print header;
    }

    # Remove the default aggregate where a group explicitly defined
    if (length(aggregating) > 1) {
        delete aggregating[""];
    }

    for (group in aggregating) {
        columnSize=split(aggregating[group], aggregate, FS);
        for (column=1; column <= columnSize; column++) {
            if (inArray(column, counts)) {
                if (inArray(column, distincts)) {
                    printf("%d", countKeyWith(column FS group FS, distinct))
                } else {
                    printf("%d", count[group])
                }
            } else if (inArray(column, sums)) {
                if (sum[column FS group] == int(sum[column FS group])) {
                    printf("%d", sum[column FS group])
                } else {
                    printf("%.4f", sum[column FS group])
                }
            } else {
                printf("%s", aggregate[column])
            }
            if (column < columnSize) {
                printf(FS)
            } else {
                printf("\n")
            }
        }
    }
}

##
# Count all elements in an array with key beginning by needle
# @param mixed needle
# @param array haystack
# @return int
function countKeyWith (needle, haystack) {
    countKey=0
    for (key in haystack) {
        if (match(key, "^" needle)) {
            countKey++;
        }
    }
    return countKey
}

##
# Checks if a value exists in an array
# @param mixed needle
# @param array haystack
# @return boolean
function inArray (needle, haystack) {
    for (key in haystack) {
        if (needle == haystack[key]) {
            return 1
        }
    }
    return 0
}