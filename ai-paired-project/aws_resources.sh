#!/bin/bash

# This script creates a VPC in AWS using the AWS CLI.
# Ensure the AWS CLI is installed and configured with the necessary permissions.
# Usage: ./aws_vpc_creation.sh <region> <vpc_name> <cidr_block>

set -x
set -e

#!/bin/bash

# Verify AWS CLI installation
if ! command -v aws &> /dev/null; then
    echo "AWS CLI not found. Install it first."
    exit 1
fi

# Verify AWS CLI configuration
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI is not configured. Run 'aws configure'."
    exit 1
fi

# Check arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <region> <vpc_name> <cidr_block>"
    exit 1
fi

region=$1
vpc_name=$2
cidr_block=$3

# Create VPC
vpc_id=$(aws ec2 create-vpc --region "$region" --cidr-block "$cidr_block" --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --region "$region" --resources "$vpc_id" --tags Key=Name,Value="$vpc_name"
echo "VPC created: $vpc_id"

