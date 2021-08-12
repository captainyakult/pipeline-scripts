#!/bin/bash

# Fail on any error.
set -o pipefail

# Set the environment.
export PATH=$HOME/pipelines/_external/cspice/exe:/usr/local/bin:$PATH

BASE=$(cd "$(dirname "$0")/../.."; pwd)

LOG_FILE=$1
LOG_FILE="${LOG_FILE##*/}"
LOG_FILE="${LOG_FILE%.*}"
LOG_FILE=$BASE/logs/$LOG_FILE.log

# Make sure we are using a good cert file.
export REQUESTS_CA_BUNDLE=$HOME/cert.pem
export SSL_CERT_FILE=$HOME/cert.pem

echo "Starting $1..." | $BASE/pipelines/logger/log.sh >> $LOG_FILE
if [[ $2 == "bg" ]]; then
	$1 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE &
else
	$1 2>&1 | $BASE/pipelines/logger/log.sh >> $LOG_FILE
fi
if [ $? -ne 0 ]; then
	echo "ERROR in script $1" >> $LOG_FILE
	echo "ERROR in script $1. Please see the log file at $LOG_FILE." | mail -s Error vtad-pipelines@jpl.nasa.gov
	exit 0
fi
echo "Completed $1." | $BASE/pipelines/logger/log.sh >> $LOG_FILE

