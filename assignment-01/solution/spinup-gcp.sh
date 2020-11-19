#!/bin/sh

INSTANCE_NAME="ubuntu-instance"
ZONE_NAME="europe-west1-b"

# 1. Prepare a modified copy of the public key as described in the GCP documentation. Use shell commands like echo, cat and file redirection (“>”). Note: the username in the prepared key must match the username specified with ssh-keygen.
echo 'TODO: Prepare a modified copy of the public key as described in the GCP documentation. Use shell commands like echo, cat and file redirection (“>”). Note: the username in the prepared key must match the username specified with ssh-keygen.'

# 2. Upload the public key into your project metadata
gcloud compute project-info add-metadata --metadata ssh-keys="${USER}:$(cat ~/.ssh/id_rsa.pub)"
echo 'Added key to project metadata'

# 3. Create a Firewall rule that allows incoming ICMP and SSH traffic. The rule must apply only for VMs with the tag “cloud-computing”.
gcloud compute firewall-rules create "cloudcomputing-rule" \
  --allow=tcp:22,icmp \
  --description="Allow incoming SSH traffic on TCP port 22 and ICMP" \
  --direction=INGRESS \
  --target-tags=cloud-computing \
  -q
echo 'Created firewall rule'

# 4. Launch an instance with the following parameters:
# - Machine type e2-standard-2
# - Add the tag “cloud-computing”
# - Image for “Ubuntu Server 18.04”
gcloud compute instances create ${INSTANCE_NAME} \
  --image-family ubuntu-1804-lts \
  --image-project ubuntu-os-cloud \
  --machine-type=e2-standard-2 \
  --tags=cloud-computing \
  --zone ${ZONE_NAME} \
  -q
echo 'Launched an instance'

# Wait until machine is up and running
echo 'TODO: Wait until machine is up and running'
sleep 30

# 5. Resize the VM disk volume size to 100 GB
gcloud compute disks resize ${INSTANCE_NAME} \
  --size=100GB \
  --zone=${ZONE_NAME} \
  -q
echo 'Resized volume'

# Get the public ip
PUBLIC_IP=$(gcloud compute instances describe ${INSTANCE_NAME} \
  --zone=${ZONE_NAME} \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
echo "Public IP is ${PUBLIC_IP}"


# Add to known hosts to avoid blocking the script by the prompt
ssh-keyscan -H $PUBLIC_IP >> ~/.ssh/known_hosts

# Install the sysbench package for Task 3
ssh -i ~/.ssh/id_rsa ${USER}@$PUBLIC_IP 'sudo apt update && sudo apt install -y sysbench'

# Copy the benchmark script
scp -i ~/.ssh/id_rsa run_bench.sh ${USER}@$PUBLIC_IP:/home/${USER}

# Create the benchmark data file with the headers
ssh -i ~/.ssh/id_rsa ${USER}@$PUBLIC_IP 'echo "time,cpu,mem,diskRand,diskSeq" >> /home/${USER}/gcp_results.csv'

# Create the crontab to be executed every 0 and 30 min marks
# The job is executed every 0th and 30th minute. The results are appended to the csv file
ssh -i ~/.ssh/id_rsa ${USER}@$PUBLIC_IP '(crontab -l 2>/dev/null; echo "0,30 * * * * bash /home/${USER}/run_bench.sh >> /home/${USER}/gcp_results.csv") | crontab -'

# Shutdown the server in 49 hours to save the sweet credits
MINUTES=$(expr 49 \* 60)
ssh -i ~/.ssh/id_rsa ${USER}@$PUBLIC_IP "sudo shutdown -P +$MINUTES"