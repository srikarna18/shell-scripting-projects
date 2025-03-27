#!/bin/bash

echo "===== Node Health Check ====="
echo "Checking system health..."

# Disk Usage Check
echo "Disk Usage:"
df -h | awk '$NF=="/" {print $5}'  # Prints root disk usage percentage

# Memory Check
echo "Memory Usage (in GB):"
free -g | awk '/Mem:/ {print "Used: " $3 "GB, Free: " $4 "GB"}'

# CPU Load Check
echo "CPU Load:"
top -bn1 | grep "load average" | awk '{print "Load Average: " $(NF-2) ", " $(NF-1) ", " $NF}'

# Number of CPU Cores
echo "CPU Cores: $(nproc)"

# Checking for ERROR logs in running processes
echo "Checking for error logs in processes..."
ERROR_PROCESSES=$(ps -ef | grep ERROR | awk '{print $2, $3}')

if [ -n "$ERROR_PROCESSES" ]; then
    echo "Found ERROR processes:"
    echo "$ERROR_PROCESSES"
else
    echo "No ERROR processes found."
fi

# Log output to a file
LOG_FILE="/var/log/node_health.log"
echo "$(date) - Node Health Check" >> $LOG_FILE
df -h >> $LOG_FILE
free -g >> $LOG_FILE
top -bn1 | head -n 10 >> $LOG_FILE
echo "$ERROR_PROCESSES" >> $LOG_FILE

echo "Health check completed. Logs saved to $LOG_FILE"
