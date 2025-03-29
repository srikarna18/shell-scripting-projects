#!/usr/bin/bash

##################################
# Author: 
# Date:
# Version:
# Description: Report of Aws Resource Usage
#################################

set -e            #Exit immediately if a command fails
set -u            #Treats unset variables as an error
set -o pipefail   #Catch errors in piped commands

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log "ERROR: AWS CLI not found. Please install it."
    exit 1
fi

# Define log file
LOG_FILE="$HOME/aws_resource_tracker.log"

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to log EC2 instances
log_ec2_instances() {
    echo "EC2 Instances:" >> "$LOG_FILE"
    aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId, State.Name, InstanceType, PublicIpAddress]" --output text >> "$LOG_FILE"
    echo "-----------------------------------------" >> "$LOG_FILE"
}

# Function to log S3 buckets
log_s3_buckets() {
    echo "S3 Buckets:" >> "$LOG_FILE"
    aws s3api list-buckets --query "Buckets[*].Name" --output text >> "$LOG_FILE"
    echo "-----------------------------------------" >> "$LOG_FILE"
}

# Function to log IAM users
log_iam_users() {
    echo "IAM Users:" >> "$LOG_FILE"
    aws iam list-users --query "Users[*].[UserName, UserId, CreateDate]" --output text >> "$LOG_FILE"
    echo "-----------------------------------------" >> "$LOG_FILE"
}

# Run functions
log_ec2_instances
log_s3_buckets
log_iam_users

# End log entry
echo "===== End of Report =====" >> "$LOG_FILE"
