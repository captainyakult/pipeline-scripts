#!/bin/bash

# Fail on any error.
set -o pipefail

# Set the environment.
export PATH=$HOME/pipelines/_external/cspice/exe:/usr/local/bin:$PATH

BASE=$(cd "$(dirname "$0")/../.."; pwd)

COMMAND=$1
shift

LOG_FILE="$COMMAND $@"
LOG_FILE="${LOG_FILE##*/}"
LOG_FILE="${LOG_FILE%.*}"
LOG_FILE="${LOG_FILE// /_}"
LOG_FILE=$BASE/logs/$LOG_FILE.log

# Make sure we are using a good cert file.
export REQUESTS_CA_BUNDLE=$HOME/cert.pem
export SSL_CERT_FILE=$HOME/cert.pem

echo "Starting $COMMAND..." | $BASE/pipelines/logger/log.sh >> $LOG_FILE
if [[ $2 == "bg" ]]; then
	shift
	$COMMAND "$@" 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE &
else
	$COMMAND "$@" 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE
fi
if [ $? -ne 0 ]; then
	echo "ERROR in script $COMMAND" >> $LOG_FILE
	echo "ERROR in script $COMMAND. Please see the log file at $LOG_FILE." | mail -s Error vtad-pipelines@jpl.nasa.gov
	exit 0
fi
echo "Completed $COMMAND." | $BASE/pipelines/logger/log.sh >> $LOG_FILE

