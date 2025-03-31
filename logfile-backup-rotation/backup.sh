#!/bin/bash

# Define log and backup directories
LOG_DIR="/path/to/logs"        # Change this to your actual log directory
BACKUP_DIR="/path/to/backup"   # Change this to your desired backup location
LOG_PATTERN="*.log"            # Adjust the pattern if needed

# Function to print error and exit script
handle_error() {
    echo "Error: $1"
    exit 1
}

# Ensure log directory exists
if [ ! -d "$LOG_DIR" ]; then
    handle_error "Log directory $LOG_DIR does not exist."
fi

# Ensure the backup directory exists or create it
mkdir -p "$BACKUP_DIR" || handle_error "Failed to create backup directory $BACKUP_DIR."

echo "Starting log rotation..."

# Get the last 5 days' dates in YYYY-MM-DD format
for i in {0..4}; do
    DATE=$(date -d "-$i day" +%Y-%m-%d)

    # Find all log files matching the date pattern
    LOG_FILES=($(ls -t "$LOG_DIR"/*"$DATE"*.log 2>/dev/null))

    # Check if logs exist for the date
    if [ ${#LOG_FILES[@]} -eq 0 ]; then
        echo "No logs found for date: $DATE."
        continue
    fi

    # Keep the latest log file
    LATEST_LOG=${LOG_FILES[0]}
    echo "Keeping latest log for $DATE: $LATEST_LOG"

    # Move all other logs to backup directory
    for FILE in "${LOG_FILES[@]:1}"; do
        BASENAME=$(basename "$FILE")
        
        if mv "$FILE" "$BACKUP_DIR/$BASENAME"; then
            echo "Backed up: $FILE -> $BACKUP_DIR/$BASENAME"
        else
            echo "Failed to move: $FILE"
        fi
    done
done

echo "Log rotation and backup completed successfully."
