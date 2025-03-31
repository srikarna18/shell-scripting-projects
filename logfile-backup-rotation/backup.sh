
#!/bin/bash

# Define log and backup directories
LOG_DIR="/path/to/logs"        # Change this to your actual log directory
BACKUP_DIR="/path/to/backup"   # Change this to your desired backup location
LOG_PATTERN="*.log"            # Adjust the pattern if needed

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Get the last 5 days' dates in YYYY-MM-DD format
for i in {0..4}; do
    DATE=$(date -d "-$i day" +%Y-%m-%d)

    # Find all log files matching the date pattern
    LOG_FILES=($(ls -t "$LOG_DIR"/*"$DATE"*.log 2>/dev/null))

    # If no logs found for the date, continue
    if [ ${#LOG_FILES[@]} -eq 0 ]; then
        echo "No logs found for date: $DATE"
        continue
    fi

    # Keep the latest log file
    LATEST_LOG=${LOG_FILES[0]}
    echo "Keeping latest log for $DATE: $LATEST_LOG"

    # Move all other logs to backup directory
    for FILE in "${LOG_FILES[@]:1}"; do
        BASENAME=$(basename "$FILE")
        mv "$FILE" "$BACKUP_DIR/$BASENAME"
        echo "Backed up: $FILE -> $BACKUP_DIR/$BASENAME"
    done
done

echo "Log rotation and backup completed."
