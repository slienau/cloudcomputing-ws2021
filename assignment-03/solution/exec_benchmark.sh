#!/bin/bash

# Create the result files
touch native-results.csv docker-results.csv kvm-results.csv qemu-results.csv 

# Write headers for the result files
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" | tee *.csv

ITERS=10

# Start the iperf server in the host machine
iperf3 -s -D

# TODO: Comments

IP_HOST=$(hostname -i)

for ((i=1; i<=$ITERS; i++))
do
    bash benchmark.sh $IP_HOST >> native-results.csv
done

docker build -t cc-docker .

for ((i=1; i<=$ITERS; i++))
do
    docker run cc-docker bash /app/benchmark.sh $IP_HOST >> docker-results.csv
done

IP_KVM=$(sudo virsh domifaddr instance-1 | grep vnet | awk '{print $4}' | cut -d '/' -f 1)
IP_QEMU=$(sudo virsh domifaddr instance-2 | grep vnet | awk '{print $4}' | cut -d '/' -f 1)


ssh-keyscan -H $IP_KVM >> ~/.ssh/known_hosts
ssh-keyscan -H $IP_QEMU >> ~/.ssh/known_hosts

scp benchmark.sh ubuntu@$IP_QEMU:
scp benchmark.sh ubuntu@$IP_KVM:

ssh ubuntu@$IP_QEMU 'sudo apt-get update && sudo apt-get install -y iperf3 sysbench'
ssh ubuntu@$IP_KVM 'sudo apt-get update && sudo apt-get install -y iperf3 sysbench'

for ((i=1; i<=$ITERS; i++))
do
    ssh ubuntu@$IP_KVM "bash benchmark.sh $IP_HOST" >> kvm-results.csv
done

for ((i=1; i<=$ITERS; i++))
do
    ssh ubuntu@$IP_QEMU "bash benchmark.sh $IP_HOST" >> qemu-results.csv
done