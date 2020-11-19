#!/bin/sh

# Assuming the amazon access information is configured with the access key and command `aws configure`
# Assuming a ssh-key pair is generated using ssh-keygen in ~/.ssh/id_rsa[.pub]

UBUNTU_SERVER_IMAGE_ID="ami-00ddb0e5626798373"
KEY_NAME="default-key"
ZONE="us-east-1f"

# 1. Get the VPC ID
VPC_ID=$(aws ec2 describe-vpcs --output text --query "Vpcs[].VpcId")

# 2. Upload the public key as a key pair
aws ec2 import-key-pair --key-name $KEY_NAME --public-key-material fileb://~/.ssh/id_rsa.pub 
echo "Key added succesfully"

# 3. Create the Security Group and Query it's id
GROUP_ID=$(aws ec2 create-security-group --group-name default_sg --description "Default security group" --vpc-id $VPC_ID --output text --query "GroupId")
echo "Security Group added"

# Enable ICMP and SSH
# -1 for all icmp range
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol icmp --port -1 --cidr 0.0.0.0/0
# 22 for ssh
aws ec2 authorize-security-group-ingress --group-id $GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "SSH and ICMP allowed"

# Create a volume of size 100G in the same zone because resizing doesn't work in our case
VOLUME_ID=$(aws ec2 create-volume --availability-zone $ZONE --size 100 --output text --query "VolumeId")

# Launch Instance and query the instance id
INSTANCE_ID=$(aws ec2 run-instances --image-id $UBUNTU_SERVER_IMAGE_ID --count 1 --instance-type t2.large --placement AvailabilityZone=$ZONE --key-name $KEY_NAME --security-group-ids $GROUP_ID --output text --query "Instances[].InstanceId")

# Wait until the instance is running and status checks are done
echo "Waiting for status checks of instance $INSTANCE_ID"
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID
echo "Instance $INSTANCE_ID is running and status checks are done"

# Attach the created 100G volume to our instance
aws ec2 attach-volume --device /dev/sda2 --instance-id $INSTANCE_ID --volume-id $VOLUME_ID

# Get the Public DNS Name
PUBLIC_DNS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text --query "Reservations[].Instances[].PublicDnsName")

# Add to known hosts to avoid blocking the script by the prompt
ssh-keyscan -H $PUBLIC_DNS >> ~/.ssh/known_hosts

# Install the sysbench package for Task 3
ssh -i ~/.ssh/id_rsa ubuntu@$PUBLIC_DNS 'sudo apt update && sudo apt install -y sysbench'

# Copy the benchmark script
scp -i ~/.ssh/id_rsa run_bench.sh ubuntu@$PUBLIC_DNS:/home/ubuntu

# Create the benchmark data file with the headers
ssh -i ~/.ssh/id_rsa ubuntu@$PUBLIC_DNS 'echo "time,cpu,mem,diskRand,diskSeq" >> /home/ubuntu/aws_results.csv'

# Create the crontab to be executed every 0 and 30 min marks
# The job is executed every 0th and 30th minute. The results are appended to the csv file
ssh -i ~/.ssh/id_rsa ubuntu@$PUBLIC_DNS '(crontab -l 2>/dev/null; echo "0,30 * * * * bash /home/ubuntu/run_bench.sh >> /home/ubuntu/aws_results.csv") | crontab -'

# Shutdown the server in 49 hours to save the sweet credits
MINUTES=$(expr 49 \* 60)
ssh -i ~/.ssh/id_rsa ubuntu@$PUBLIC_DNS "sudo shutdown -P +$MINUTES"
