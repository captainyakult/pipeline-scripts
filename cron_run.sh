#!/bin/bash

# Fail on any error.
set -o pipefail

export BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Store and remove the first param as the command from the rest so that $@ works.
COMMAND=$1
shift

# Setup the log file path.
LOG_FILE="$COMMAND"
LOG_FILE="${LOG_FILE##*/}" # remove everything before the last slash
LOG_FILE="${LOG_FILE%.*}" # remove everything after the last period
LOG_FILE="$LOG_FILE $@" # add on the params
LOG_FILE="${LOG_FILE%"${LOG_FILE##*[![:space:]]}"}" # trim trailing white space
LOG_FILE="${LOG_FILE// /_}" # turn any spaces into underscores
LOG_FILE=$BASE/logs/$LOG_FILE.log # prepend the log path

# Make sure we are using a good cert file.
export REQUESTS_CA_BUNDLE=$HOME/cert.pem
export SSL_CERT_FILE=$HOME/cert.pem

function run {
	"$@" 2>&1 | awk '{ print strftime("%Y-%m-%d %H:%M:%S"), $0; fflush(); }' >> $LOG_FILE
}

run echo Starting $COMMAND

run $COMMAND "$@"

if [ $? -ne 0 ]; then
	run echo "ERROR in script $COMMAND"
	echo "ERROR in script $COMMAND. Please see the log file at $LOG_FILE." | mail -s Error vtad-pipelines@jpl.nasa.gov hurley@jpl.nasa.gov
	exit 0
fi
run echo Completed $COMMAND.

