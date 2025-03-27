#!/usr/bin/bash 

#############  METADATA   ########
#Author:
#Date:
#Version:
#Description:
##################################

set -e #Exit on Error
set -x #Debug Mode
set -o #pipefail or typo
or
set -exo # Enable exit on error and debugging and typo



df -h

free -g

nproc

top

ps -ef | grep -E "ERROR"  # finds both error logs

ps -ef | grep ERROR | awk -F" " '{print $2, $3}' # prints pid ppid of error log
