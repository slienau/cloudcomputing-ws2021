#!/bin/sh

TAG="cc"
ZONE_NAME="europe-west1-b"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#1. Create two additional VPC networks “cc-network1” and
#“cc-network2” with subnet-mode “custom”.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gcloud compute networks create cc-network1 \
    --subnet-mode=custom

gcloud compute networks create cc-network2 \
    --subnet-mode=custom

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#2. For each created network, create a respective subnet “cc-subnet1”
#and “cc-subnet2” and assign different IP ranges to them.
#Furthermore, “ccsubnet1” needs a secondary range
#(check the --secondary-range parameter).
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gcloud compute networks subnets create cc-subnet1 \
    --network=cc-network1 \
    --region=europe-west1 \
    --range=10.0.0.0/24 \
    --secondary-range range-1=192.0.1.0/24
#IP: 10.0.0.0/24 ?

gcloud compute networks subnets create cc-subnet2 \
    --network=cc-network2 \
    --region=europe-west1 \
    --range=12.0.0.0/24
#IP: 10.0.1.0/24 ?

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#4. Create a disk based on an “Ubuntu Server 18.04” image in your
#default zone and set the size to at least 100GB
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gcloud compute disks create my-disk \
    --image ubuntu-1804-bionic-v20201201 \
    --image-project ubuntu-os-cloud \
    --size=200gb \
    --type=pd-standard \
    --zone=$ZONE_NAME

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 5. Use the disk to create a custom image and
# include the required license for nested virtualization.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gcloud compute images create nested-vm-image \
    --source-disk my-disk --source-disk-zone $ZONE_NAME \
    --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 6. Start 3 VMs that allow nested virtualization:

# Name them “controller”, “compute1”, “compute2”

# The image should be the previously created custom
# image that supports nested virtualization.

# Set the tag “cc” for each VM.

# Choose machine type “n2-standard-2”

# The VMs must have 2 NICs (check the --network-interface parameter).
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gcloud compute instances create "controller" \
    --zone $ZONE_NAME \
    --image nested-vm-image \
    --tags=$TAG \
    --machine-type=n2-standard-2 \
    --network-interface network=cc-network1,subnet=cc-subnet1,aliases=range-1:/24 \
    --network-interface network=cc-network2,subnet=cc-subnet2

gcloud compute instances create "compute1" \
    --zone $ZONE_NAME \
    --image nested-vm-image \
    --tags=$TAG \
    --machine-type=n2-standard-2 \
    --network-interface network=cc-network1,subnet=cc-subnet1 \
    --network-interface network=cc-network2,subnet=cc-subnet2

gcloud compute instances create "compute2" \
    --zone $ZONE_NAME \
    --image nested-vm-image \
    --tags=$TAG \
    --machine-type=n2-standard-2 \
    --network-interface network=cc-network1,subnet=cc-subnet1 \
    --network-interface network=cc-network2,subnet=cc-subnet2

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 7. Create a firewall rule that allows all tcp, icmp and udp traffic
# for the IP ranges of cc-subnet1 and cc-subnet2.
# Restrict it to VMs that have the “cc”tag.

# REMINDER: check network parameter
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
gcloud compute firewall-rules create "internal-rule" \
    --allow=tcp,udp,icmp \
    --direction=INGRESS \
    --target-tags=$TAG \
    --source-ranges="10.0.0.0/23"

gcloud compute firewall-rules create "openstack-external-rule" \
    --network cc-network1 \
    --allow=tcp,icmp \
    --direction=INGRESS \
    --target-tags=$TAG \
    --source-ranges="0.0.0.0/0"
