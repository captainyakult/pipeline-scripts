#!/bin/bash

# Fail on any error.
set -o pipefail

export BASE=$(cd "$(dirname "$0")/../.."; pwd)

# Store and remove the first param as the command from the rest so that $@ works.
COMMAND=$1
shift

# Setup the log file path.
LOG_NAME="$COMMAND"
LOG_NAME="${LOG_NAME##*/}" # remove everything before the last slash
LOG_NAME="${LOG_NAME%.*}" # remove everything after the last period
LOG_NAME="$LOG_NAME $@" # add on the params
LOG_NAME="${LOG_NAME%"${LOG_NAME##*[![:space:]]}"}" # trim trailing white space
LOG_NAME="${LOG_NAME// /_}" # turn any spaces into underscores
LOG_FILE=$BASE/logs/$LOG_NAME.log # prepend the log path

# # Make sure we are using a good cert file.
# export REQUESTS_CA_BUNDLE=$HOME/data/cert.pem
# export SSL_CERT_FILE=$HOME/data/cert.pem

function log_error {
	echo "$1" | $BASE/code/scripts/log.sh >> $LOG_FILE
	echo "$1. Please see the log file at $LOG_FILE." | mail -s Error vtad-pipelines@jpl.nasa.gov
}

# Lock the code so that it never runs more then once at a time.
(
	flock -n 99 || {
		log_error "ERROR: Could not start script. The script is already running."
		exit 0
	}

	echo "Starting $COMMAND $@..." | $BASE/code/scripts/log.sh >> $LOG_FILE

	if [[ $2 == "bg" ]]; then
		shift
		$COMMAND "$@" 2>&1 | $BASE/code/scripts/log.sh >> $LOG_FILE &
	else
		$COMMAND "$@" 2>&1 | $BASE/code/scripts/log.sh >> $LOG_FILE
	fi

	if [ $? -ne 0 ]; then
		log_error "ERROR in script $COMMAND"
		exit 0
	fi

	echo "Completed $COMMAND" | $BASE/code/scripts/log.sh >> $LOG_FILE

) 99>/var/lock/`basename $LOG_NAME`

