#!/bin/bash

# Fail on any error.
set -o pipefail

# Set the environment.
export PATH=/usr/local/gcc-4.9.0/bin:$HOME/pipelines/animdatagen/cspice/exe:/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/gcc-4.9.0/lib64/

BASE=$(cd "$(dirname "$0")/../.."; pwd)

LOG_FILE=$1
LOG_FILE="${LOG_FILE##*/}"
LOG_FILE="${LOG_FILE%.*}"
LOG_FILE=$BASE/logs/$LOG_FILE.log

echo "Starting $1..." | $BASE/pipelines/logger/log.sh >> $LOG_FILE
if [[ $2 == "bg" ]]; then
	$1 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE &
else
	$1 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE
fi
if [ $? -eq 1 ]; then
	echo "ERROR in script $1" >> $LOG_FILE
	echo "ERROR in script $1. Please see the log file at $LOG_FILE." | mail -s Error vtad-pipelines@jpl.nasa.gov
	exit 0
fi
echo "Completed $1." | $BASE/pipelines/logger/log.sh >> $LOG_FILE

