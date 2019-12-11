#!/bin/bash

# Fail on any error.
set -o pipefail

BASE=$(cd "$(dirname "$0")/../.."; pwd)

LOG_FILE=$1
LOG_FILE="${LOG_FILE##*/}"
LOG_FILE="${LOG_FILE%.*}"
LOG_FILE=$BASE/logs/$LOG_FILE.log

echo "Starting $1..." | $BASE/pipelines/logger/log.sh >> $LOG_FILE
$1 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE
if [ $? -eq 1 ]; then
	echo "ERROR in script $1" >> $LOG_FILE
	echo "ERROR in script $1. Please see the log file at $LOG_FILE." | mail -s Error vtad-pipelines@jpl.nasa.gov
	exit 0
fi
echo "Completed $1." | $BASE/pipelines/logger/log.sh >> $LOG_FILE

