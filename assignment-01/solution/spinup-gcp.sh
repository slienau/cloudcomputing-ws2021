#!/bin/sh

VM_NAME="ubuntu-cc2"
ZONE_NAME="europe-west1-b"

# 1. Prepare a modified copy of the public key as described in the GCP documentation. Use shell commands like echo, cat and file redirection (“>”). Note: the username in the prepared key must match the username specified with ssh-keygen.
echo 'TODO: Prepare a modified copy of the public key as described in the GCP documentation. Use shell commands like echo, cat and file redirection (“>”). Note: the username in the prepared key must match the username specified with ssh-keygen.'

# 2. Upload the public key into your project metadata
echo 'TODO: Upload the public key into your project metadata'

# 3. Create a Firewall rule that allows incoming ICMP and SSH traffic. The rule must apply only for VMs with the tag “cloud-computing”.
gcloud compute firewall-rules create "cloudcomputing-rule" --allow=tcp:22,icmp --description="Allow incoming SSH traffic on TCP port 22 and ICMP" --direction=INGRESS --target-tags=cloud-computing

# 4. Launch an instance with the following parameters:
# - Machine type e2-standard-2
# - Add the tag “cloud-computing”
# - Image for “Ubuntu Server 18.04”
gcloud compute instances create ${VM_NAME} --image-family ubuntu-1804-lts --image-project ubuntu-os-cloud --machine-type=e2-standard-2 --tags=cloud-computing --zone ${ZONE_NAME}

# 5. Resize the VM disk volume size to 100 GB
gcloud compute disks resize ${VM_NAME} --size=100GB --zone=${ZONE_NAME}