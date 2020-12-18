#!/bin/bash

# Create the result files
touch native-results.csv docker-results.csv kvm-results.csv qemu-results.csv 

# Write headers for the result files
echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" | tee *.csv

# Start the iperf server in the host machine
iperf3 -s -D

# TODO: Comments

IP_HOST=$(hostname -I | cut -d ' ' -f1)

for i in {1..10}
do
    bash benchmark.sh $IP_HOST >> native-results.csv
done

docker build -t cc-docker .

for i in {1..10}
do
    docker run cc-docker bash /app/benchmark.sh $IP_HOST >> docker-results.csv
done

IP_KVM=$(sudo virsh domifaddr instance-1 | grep vnet | awk '{print $4}' | cut -d '/' -f 1)
IP_QEMU=$(sudo virsh domifaddr instance-2 | grep vnet | awk '{print $4}' | cut -d '/' -f 1)

ssh ubuntu@$IP_QEMU 'mkdir /app'
ssh ubuntu@$IP_KVM 'mkdir /app'

scp benchmark.sh ubuntu@$IP_QEMU:/app/
scp benchmark.sh ubuntu@$IP_KVM:/app/

ssh ubuntu@$IP_QEMU 'sudo apt-get update && sudo apt-get install -y iperf3 sysbench'
ssh ubuntu@$IP_KVM 'sudo apt-get update && sudo apt-get install -y iperf3 sysbench'

for i in {1..10}
do
    ssh ubuntu@$IP_KVM 'bash /app/benchmark.sh $IP_HOST' >> kvm-results.csv
done

for i in {1..10}
do
    ssh ubuntu@$IP_QEMU 'bash /app/benchmark.sh $IP_HOST' >> qemu-results.csv
done