# cron-run

Runs a script, using the logger to prepend dates to the log and writing the log to the $BASE/logs folder. If there is an error, mails to the user.

If you add a second parameter of "bg", then the command will return immediately, even if the process continues to run, which is useful for persistent processes.
