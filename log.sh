#! /bin/bash

# Output each stdout and sterror line with a prefix of the ISO timestamp to both stdout and the given file.
while IFS= read -r line; do
        time=`date "+%Y-%m-%d %H:%M:%S"`
        echo "$time $line"
done

