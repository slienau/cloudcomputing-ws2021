FROM ubuntu:18.04
COPY benchmark.sh /app/
COPY forkbench /bin/
RUN chmod 777 /app/benchmark.sh
RUN apt-get update && apt-get install -y bc sysbench iperf3