#!/bin/bash

set -x #debug mode

# Set Variables
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
REGION="us-east-1"
AMI_ID="ami-0c55b159cbfafe1f0"  # Change this based on your region
INSTANCE_TYPE="t2.micro"
KEY_NAME="my-key"
BUCKET_NAME="my-unique-s3-bucket-$RANDOM"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "AWS CLI could not be found. Please install it first."
    exit 1
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "AWS CLI is not configured. Please configure it using 'aws configure'."
    exit 1
fi

# Check correct arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 {create|teardown}"
    exit 1
fi

# Check Argument
if [ "$1" == "create" ]; then
    echo "Creating AWS resources..."
    
    # Create VPC
    echo "Creating VPC..."
    VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
    if [ -z "$VPC_ID" ]; then
        echo "Failed to create VPC."
        exit 1
    fi
    echo "VPC ID: $VPC_ID"

    # Create Subnet
    echo "Creating Subnet..."
    SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --region $REGION --query 'Subnet.SubnetId' --output text)
    if [ -z "$SUBNET_ID" ]; then
        echo "Failed to create Subnet."
        exit 1
    fi
    echo "Created Subnet: $SUBNET_ID"

    # Create Internet Gateway
    echo "Creating Internet Gateway..."
    IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
    if [ -z "$IGW_ID" ]; then
        echo "Failed to create Internet Gateway."
        exit 1
    fi
    echo "Created Internet Gateway: $IGW_ID"
    aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION

    # Create Route Table & Route to IGW
    echo "Creating Route Table..."
    RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
    if [ -z "$RTB_ID" ]; then
        echo "Failed to create Route Table."
        exit 1
    fi
    echo "Created Route Table: $RTB_ID"
    aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
    aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id $SUBNET_ID --region $REGION

    # Create Security Group
    echo "Creating Security Group..."
    SG_ID=$(aws ec2 create-security-group --group-name my-security-group --description "Allow SSH and HTTP" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
    if [ -z "$SG_ID" ]; then
        echo "Failed to create Security Group."
        exit 1
    fi
    echo "Created Security Group: $SG_ID"
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
    aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION

    # Create EC2 Key Pair
    echo "Creating EC2 Key Pair..."
    KEY_FILE_PATH="$HOME/${KEY_NAME}.pem"

    # Check if the key pair already exists
    if aws ec2 describe-key-pairs --key-names $KEY_NAME --region $REGION &> /dev/null; then
        echo "Key pair $KEY_NAME already exists. Deleting it..."
        aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
        rm -f "$KEY_FILE_PATH"
        # Add a small delay to ensure the deletion is fully processed
        sleep 5
    fi

    # Create a new key pair
    aws ec2 create-key-pair --key-name $KEY_NAME --region $REGION --query 'KeyMaterial' --output text > $KEY_FILE_PATH
    chmod 400 $KEY_FILE_PATH
    echo "Created Key Pair: $KEY_NAME and saved to $KEY_FILE_PATH"

    # Launch EC2 Instance
    echo "Launching EC2 Instance..."
    AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" --query "Images[0].ImageId" --region $REGION --output text)
    if [ -z "$AMI_ID" ]; then
        echo "Failed to find a valid AMI ID."
        exit 1
    fi
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --region $REGION --query 'Instances[0].InstanceId' --output text)
    if [ -z "$INSTANCE_ID" ]; then
        echo "Failed to launch EC2 Instance."
        exit 1
    fi
    echo "Launched EC2 Instance: $INSTANCE_ID"

    # Create S3 Bucket
    echo "Creating S3 Bucket..."
    aws s3 mb s3://$BUCKET_NAME --region $REGION
    echo "Created S3 Bucket: $BUCKET_NAME"

    # Disable Block Public Access
    echo "Disabling Block Public Access for S3 Bucket..."
    aws s3api put-public-access-block --bucket $BUCKET_NAME --region $REGION --public-access-block-configuration \
        BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false
    echo "Disabled Block Public Access for Bucket: $BUCKET_NAME"

elif [ "$1" == "teardown" ]; then
    echo "Tearing down AWS resources..."
    
    # Terminate EC2 Instance
    echo "Terminating EC2 Instance..."
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
    echo "Terminated EC2 Instance: $INSTANCE_ID"

    # Delete Security Group
    echo "Deleting Security Group..."
    aws ec2 delete-security-group --group-id $SG_ID --region $REGION
    echo "Deleted Security Group: $SG_ID"

    # Detach and Delete Internet Gateway
    echo "Deleting Internet Gateway..."
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
    echo "Deleted Internet Gateway: $IGW_ID"

    # Delete Route Table
    echo "Deleting Route Table..."
    aws ec2 delete-route-table --route-table-id $RTB_ID --region $REGION
    echo "Deleted Route Table: $RTB_ID"

    # Delete Subnet
    echo "Deleting Subnet..."
    aws ec2 delete-subnet --subnet-id $SUBNET_ID --region $REGION
    echo "Deleted Subnet: $SUBNET_ID"

    # Delete VPC
    echo "Deleting VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
    echo "Deleted VPC: $VPC_ID"

    # Delete S3 Bucket
    echo "Deleting S3 Bucket..."
    aws s3 rb s3://$BUCKET_NAME --force --region $REGION
    echo "Deleted S3 Bucket: $BUCKET_NAME"

    # Delete Key Pair
    echo "Deleting Key Pair..."
    rm -f "$KEY_FILE_PATH"
    aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
    echo "Deleted Key Pair: $KEY_NAME"

else
    echo "Usage: $0 {create|teardown}"
    exit 1
fi
