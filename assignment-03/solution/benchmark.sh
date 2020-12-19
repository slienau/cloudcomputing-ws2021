#!/bin/bash

if [ "$1" == "" ]; then
    echo "Provide host IP address as the first parameter. $(hostname -i)"
    exit 1
fi

host_ip=$1

# This script benchmarks CPU, memory and random/sequential disk access.
# Some debug output is written to stderr, and the final benchmark result is output on stdout as a single CSV-formatted line.

# Execute the sysbench tests for the given number of seconds
runtime=60

# Record the Unix timestamp before starting the benchmarks.
time=$(date +%s)

# Run the sysbench CPU test and extract the "events per second" line.
1>&2 echo "Running CPU test..."
cpu=$(sysbench --time=$runtime cpu run | grep "events per second" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench memory test and extract the "transferred" line. Set large total memory size so the benchmark does not end prematurely.
1>&2 echo "Running memory test..."
mem=$(sysbench --time=$runtime --memory-block-size=4K --memory-total-size=100T memory run | grep -oP 'transferred \(\K[0-9\.]*')

# Prepare one file (1GB) for the disk benchmarks
1>&2 sysbench --file-total-size=1G --file-num=1 fileio prepare

# Run the sysbench sequential disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio sequential read test..."
diskSeq=$(sysbench --time=$runtime --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench random access disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio random read test..."
diskRand=$(sysbench --time=$runtime --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

# Run the forkbench test
1>&2 echo "Running fork test..."

# Create an empty array to store forkspersec per test
vallist=()

# Time the start
start=$SECONDS

# Execute until duration has passed, discard the last test, (might as well keep it)
while true
do 
    forkspersec=$(forkbench 0 3000 2> /dev/null)
    if [[ $((SECONDS - start)) -gt $runtime ]]
    then
        break
    fi
    vallist+=($forkspersec)
done

# Create an expression for calculating the mean with 2 decimal points
expression="scale=2;("

# Add all values
for val in "${vallist[@]}"
do  
    expression+="$val+"
done

expression=${expression::-1}
expression+=")/"

# Divide by the number of tests
expression+="${#vallist[@]}"

#Evaluate the expression
fork=$(echo $expression | bc -l)

# Run the uplink test
1>&2 echo "Running uplink test..."
uplink=$(iperf3 -4 -P 5 -f m -t $runtime -c $host_ip | tail -3 | head -1 | awk '{print $6}')

# Output the benchmark results as one CSV line
echo "$time,$cpu,$mem,$diskRand,$diskSeq,$fork,$uplink"
