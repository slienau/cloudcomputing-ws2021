FROM ubuntu:18.04
COPY benchmark.sh /app/
RUN chmod 777 /app/benchmark.sh
RUN apt-get update && apt-get install -y sysbench iperf3