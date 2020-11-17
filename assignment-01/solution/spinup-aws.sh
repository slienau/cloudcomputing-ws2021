#!/bin/sh

UBUNTU_SERVER_IMAGE_ID="ami-00ddb0e5626798373"
KEY_NAME="default-key"
ZONE="us-east-1f"

# 1. Get the VPC ID
VPC_ID=$(aws ec2 describe-vpcs --output text --query "Vpcs[].VpcId")

# 2. Upload the public key as a key pair
aws ec2 import-key-pair --key-name $KEY_NAME --public-key-material fileb://~/.ssh/id_rsa.pub 

# 3. Create the Security Group and Query it's id
GROUP_ID=$(aws ec2 create-security-group --group-name default_sg --description "Default security group" --vpc-id $VPC_ID --output text --query "GroupId")

# Enable ICMP and SSH
# -1 for all icmp range
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol icmp --port -1 --cidr 0.0.0.0/0
# 22 for ssh
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0

# Create a volume of size 100G in the same zone because resizing doesn't work in our case
VOLUME_ID=$(aws ec2 create-volume --availability-zone us-east-1f --size 100 --output text --query "VolumeId")

# Launch Instance and query the instance id
INSTANCE_ID=$(aws ec2 run-instances --image-id $UBUNTU_SERVER_IMAGE_ID --count 1 --instance-type t2.large --placement AvailabilityZone=$ZONE --key-name $KEY_NAME --security-group-ids $GROUP_ID --output text --query "Instances[].InstanceId")

# Wait until the instance is running
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Attach the created 100G volume to our instance
aws ec2 attach-volume --device /dev/sda2 --instance-id $INSTANCE_ID --volume-id $VOLUME_ID
