#!/bin/bash

# Create the result files
touch native-results.csv docker-results.csv kvm-results.csv qemu-results.csv 

# Write headers for the result files
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" | tee *.csv

# 10 iterations for a bencmark
ITERS=10

# We assume the forkbench binary is readily available, we did not compile the code here
# make forkbench can be also done here and executable can be created again
sudo cp forkbench /bin

# Start the iperf server in the host machine
iperf3 -s -D

# Get the ip of the host machine
IP_HOST=$(hostname -i)

# Execute the benchmarks in the experiment host
for ((i=1; i<=$ITERS; i++))
do
    bash benchmark.sh $IP_HOST >> native-results.csv
done

# Build the docker image from the Dockerfile in the directory
docker build -t cc-docker .

# Execute the benchmarks in a docker container based on cc-docker image
for ((i=1; i<=$ITERS; i++))
do
    docker run cc-docker bash /app/benchmark.sh $IP_HOST >> docker-results.csv
done

# Get the IP's of KVM and QEMU VM's
IP_KVM=$(sudo virsh domifaddr instance-1 | grep vnet | awk '{print $4}' | cut -d '/' -f 1)
IP_QEMU=$(sudo virsh domifaddr instance-2 | grep vnet | awk '{print $4}' | cut -d '/' -f 1)

# Add them to known hosts to continue without getting prompted
ssh-keyscan -H $IP_KVM >> ~/.ssh/known_hosts
ssh-keyscan -H $IP_QEMU >> ~/.ssh/known_hosts

# Copy the benchmark files to home folder
scp benchmark.sh ubuntu@$IP_QEMU:
scp benchmark.sh ubuntu@$IP_KVM:

# Copy the forkbench executable to home folder
scp forkbench ubuntu@$IP_QEMU:
scp forkbench ubuntu@$IP_KVM:

# Move the forkbench exec to /bin, to make it globally executable
ssh ubuntu@$IP_QEMU 'sudo mv forkbench /bin'
ssh ubuntu@$IP_KVM 'sudo mv forkbench /bin'

# Install bc iperf3 and sysbench
ssh ubuntu@$IP_QEMU 'sudo apt-get update && sudo apt-get install -y bc iperf3 sysbench'
ssh ubuntu@$IP_KVM 'sudo apt-get update && sudo apt-get install -y bc iperf3 sysbench'

# Execute the benchmarks in QEMU VM
for ((i=1; i<=$ITERS; i++))
do
    ssh ubuntu@$IP_QEMU "bash benchmark.sh $IP_HOST" >> qemu-results.csv
done

# Execute the benchmarks in KVM VM
for ((i=1; i<=$ITERS; i++))
do
    ssh ubuntu@$IP_KVM "bash benchmark.sh $IP_HOST" >> kvm-results.csv
done
