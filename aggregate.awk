#!/bin/awk -f

##
# Aggregate a CSV file and expose the COUNT, SUM and DISTINCT methods
# @param string header New header line
# @param int omitHeader If 1, exclude the first line
# @param int distinctLine If, aggregate by the entire line
# @param string distinctColumns List of columns by index to use in single mode
# @param string countColumns List of columns by index to count, separated by space
# @param string sumColumns List of columns by index to sum, separated by space
# @param string groupByColumns List of columns by index to use to group, separated by space
#
# @copyright 2016 Hervé Gouchet
# @license http://www.apache.org/licenses/LICENSE-2.0
# @source https://github.com/rvflash/termtables

BEGIN {
    # Separators (input)
    FS=",";

    # Skip header line
    start=1;
    if (1 == omitHeader) {
        start++;
    }

    # Manage empty input file and default value
    aggregating[""]="";
    count[""]=0;
    distinct[""]=0;
    sum[""]=0;
    numberFields=0;

    # Convert string args to array
    split(distinctColumns, distincts, " ");
    split(countColumns, counts, " ");
    split(sumColumns, sums, " ");
    split(groupByColumns, groups, " ");
}
(NR >= start) {
    # Split line with comma separated values and deal with comma inside quotes
    numberFields=splitLine($0, columns);

    # Group by (single or multiple columns)
    if (1 == distinctLine) {
        group=$0;
    } else {
        group="";
        for (column in groups) {
            if ("" == group) {
                group=columns[groups[column]];
            } else {
                group=group FS columns[groups[column]];
            }
        }
    }

    # Distinct (if no group has been defined but first column requested as distinct value, use it for grouping)
    if ("" == group && inArray(1, distincts)) {
        group=columns[1];
    }
    aggregating[group]=$0;

    # Count
    count[group]++;
    for (column in counts) {
        if (inArray(counts[column], distincts)) {
            distinct[counts[column] FS group FS columns[counts[column]]]++;
        }
    }

    # Sum
    for (column in sums) {
        sum[sums[column] FS group]+=columns[sums[column]];
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
        numberFields=splitLine(aggregating[group], columns);
        for (column=1; column <= numberFields; column++) {
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
                # Protect column containing comma by quotes
                printf("%s", (columns[column] ~ FS ? "\"" columns[column] "\"" : columns[column]))
            }
            if (column < numberFields) {
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

##
# Split line and deal with escaping separator within double quotes
# Cheating with CSV file that contains comma inside a quoted field
# @param string line
# @param array columns
# @return int
function splitLine (line, columns)
{
    numberFields=0;
    line=line FS;

    while(line) {
        match(line, / *"[^"]*" *,|[^,]*,/);
        field=substr(line, RSTART, RLENGTH);
        # Remove extra data
        gsub(/^ *"?|"? *,$/, "", field);
        numberFields++;
        columns[numberFields]=field;
        # So, next ?
        line=substr(line, RLENGTH+1);
    }
    return numberFields
}