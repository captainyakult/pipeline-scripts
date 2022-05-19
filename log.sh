#! /bin/bash

# Set the indent to null if nothing has changed it.
LOG_INDENT=${LOG_INDENT:-0}

# Output each stdout and sterror line with a prefix of the ISO timestamp to both stdout and the given file.
while IFS= read -r line; do
	time=`date "+%Y-%m-%d %H:%M:%S"`
	echo "$time $line"
done
