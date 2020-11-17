#!/bin/bash

SYSBENCH_EXECUTION_TIME=60

# ~~~~~~~~~~~~~~~~~~~~~
# CPU events per second
# ~~~~~~~~~~~~~~~~~~~~~
CPU=$(sysbench cpu --time=${SYSBENCH_EXECUTION_TIME} run | grep "events per second" | sed "s/events per second://g" | sed -e 's/^[ \\t]*//')


# ~~~~~~~~~~~~~
# memory access
# ~~~~~~~~~~~~~
MEMORY=$(sysbench memory --time=${SYSBENCH_EXECUTION_TIME} --memory-block-size=4KB --memory-total-size=100TB run | grep "MiB transferred" | cut -d "(" -f2 | cut -d ")" -f1 | sed 's#MiB/sec##g' | sed 's/^[ \t]*//;s/[ \t]*$//')


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# random-access disk read speed
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# prepare
sysbench fileio --file-test-mode=rndrd --file-num=1 --file-total-size=1G --file-extra-flags=direct prepare > /dev/null

# execute
FILEIO_RANDOM_ACCESS=$(sysbench fileio --time=${SYSBENCH_EXECUTION_TIME} --file-test-mode=rndrd --file-num=1 --file-total-size=1G --file-extra-flags=direct run | grep "read, MiB/s:" | sed 's#read, MiB/s:##g' | sed 's/^[ \t]*//;s/[ \t]*$//')

# cleanup
sysbench fileio --file-test-mode=rndrd --file-num=1 --file-total-size=1G --file-extra-flags=direct cleanup > /dev/null


# ~~~~~~~~~~~~~~~~~~~~~~~~~~
# sequential disk read speed
# ~~~~~~~~~~~~~~~~~~~~~~~~~~

# prepare
sysbench fileio --file-test-mode=seqrd --file-num=1 --file-total-size=1G --file-extra-flags=direct prepare > /dev/null

# execute
FILEIO_SEQUENTIAL=$(sysbench fileio --time=${SYSBENCH_EXECUTION_TIME} --file-test-mode=seqrd --file-num=1 --file-total-size=1G --file-extra-flags=direct run | grep "read, MiB/s:" | sed 's#read, MiB/s:##g' | sed 's/^[ \t]*//;s/[ \t]*$//')

# cleanup
sysbench fileio --file-test-mode=seqrd --file-num=1 --file-total-size=1G --file-extra-flags=direct cleanup > /dev/null


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# format output (time,cpu,mem,diskRand,diskSeq)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo $(date +%s),$CPU,$MEMORY,$FILEIO_RANDOM_ACCESS,$FILEIO_SEQUENTIAL
