#!/bin/bash

# Set Variables
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
REGION="us-east-1"
AMI_ID="ami-0c55b159cbfafe1f0"  # Change this based on your region
INSTANCE_TYPE="t2.micro"
KEY_NAME="my-key"
BUCKET_NAME="my-unique-s3-bucket-$RANDOM"

# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
echo "Created VPC: $VPC_ID"

# Create Subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --query 'Subnet.SubnetId' --output text)
echo "Created Subnet: $SUBNET_ID"

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
echo "Created Internet Gateway: $IGW_ID"
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

# Create Route Table & Route to IGW
RTB_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
echo "Created Route Table: $RTB_ID"
aws ec2 create-route --route-table-id $RTB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $RTB_ID --subnet-id $SUBNET_ID

# Create Security Group
SG_ID=$(aws ec2 create-security-group --group-name my-security-group --description "Allow SSH and HTTP" --vpc-id $VPC_ID --query 'GroupId' --output text)
echo "Created Security Group: $SG_ID"
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0

# Create EC2 Key Pair
aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo "Created Key Pair: $KEY_NAME"

# Launch EC2 Instance
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --key-name $KEY_NAME --security-group-ids $SG_ID --subnet-id $SUBNET_ID --query 'Instances[0].InstanceId' --output text)
echo "Launched EC2 Instance: $INSTANCE_ID"

# Create S3 Bucket
aws s3 mb s3://$BUCKET_NAME
aws s3api put-bucket-acl --bucket $BUCKET_NAME --acl public-read

echo "Created S3 Bucket: $BUCKET_NAME"
