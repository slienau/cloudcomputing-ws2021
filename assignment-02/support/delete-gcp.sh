#!/bin/bash

TAG="cc"

# delete firewall rules
gcloud compute firewall-rules delete openstack-external-rule -q
gcloud compute firewall-rules delete internal-rule1 -q
gcloud compute firewall-rules delete internal-rule2 -q

# delete vm instances
gcloud compute instances delete compute2 -q
gcloud compute instances delete compute1 -q
gcloud compute instances delete controller -q

# delete network
gcloud compute networks subnets delete cc-subnet1 -q
gcloud compute networks subnets delete cc-subnet2 -q
gcloud compute networks delete cc-network1 -q
gcloud compute networks delete cc-network2 -q

# delete image and disk
gcloud compute images delete nested-vm-image -q
gcloud compute disks delete my-disk -q
