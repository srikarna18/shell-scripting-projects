
log rotation script that keeps the latest log file for each of the past 5 days, deletes the rest, and backs up deleted logs into a separate backup directory.

If you want to automate the script to run daily, use cron:

Open the cron job editor:
run
crontab -e

Add this line at the end to run the script every day at midnight:
0 9,17 * * * /path/to/log_rotate_5_days_backup.sh

Save and exit.
