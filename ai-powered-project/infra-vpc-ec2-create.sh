#!/bin/bash

# Set variables
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR="10.0.1.0/24"
AMI_ID="ami-12345678"  # Replace with your AMI ID
INSTANCE_TYPE="t2.micro"
KEY_NAME="my-key"  # Replace with your key pair name

# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
echo "Created VPC: $VPC_ID"

# Create Subnet
SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_CIDR --query 'Subnet.SubnetId' --output text)
echo "Created Subnet: $SUBNET_ID"

# Create Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
echo "Created Internet Gateway: $IGW_ID"

# Attach Internet Gateway to VPC
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Attached Internet Gateway to VPC"

# Create Route Table
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
echo "Created Route Table: $ROUTE_TABLE_ID"

# Create Route for Internet Access
aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
echo "Created Route for Internet Access"

# Associate Route Table with Subnet
aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $SUBNET_ID
echo "Associated Route Table with Subnet"

# Create Security Group
SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name my-security-group --description "Allow SSH and HTTP" --vpc-id $VPC_ID --query 'GroupId' --output text)
echo "Created Security Group: $SECURITY_GROUP_ID"

# Allow SSH and HTTP Access
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
echo "Allowed SSH and HTTP access"

# Launch EC2 instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SECURITY_GROUP_ID \
  --subnet-id $SUBNET_ID \
  --associate-public-ip-address \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Launched EC2 Instance: $INSTANCE_ID"

# Wait for instance to be in running state
echo "Waiting for instance to be in running state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

echo "Instance is now running."

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo "EC2 Instance Public IP: $PUBLIC_IP"

# Wait for SSH to be ready
echo "Waiting for SSH service on EC2 instance..."
sleep 60  # Give some time for SSH to be available

# Configure EC2 instance (example: update packages and install Apache)
echo "Configuring EC2 instance..."
ssh -o StrictHostKeyChecking=no -i "$KEY_NAME.pem" ec2-user@$PUBLIC_IP << 'EOF'
  sudo yum update -y
  sudo yum install -y httpd
  sudo systemctl start httpd
  sudo systemctl enable httpd
EOF

echo "EC2 instance setup completed."
