#!/usr/bin/env bash 

# Usage: kafka-consumer-lag.sh -i kafka_server -o elasticsearch_url -t <interval_second> group1 [group2 .. groupN]

# TOPIC, PARTION, CURRENT-OFFSET, LOG-END-OFFSET, LAG, CONSUMER-ID, HOST, CLIENT-ID

# Requires: $KAFKA_HOME/bin/kafka-consumer-groups.sh, awk, jq, curl

sed_expr='3,$p'

awk_expr='BEGIN { printf "["; } { for(i = 1; i < NF; i++) { printf "\"%s\",", $i; } printf "\"%s\"", $i; } END { printf "]\n"; }'

jq_expr='{consumerGroup: "xxxxx", consumerId: .[5], host: .[6], clientId: .[7], topic: .[0], partition: .[1]|tonumber, currentOffset: .[2]|tonumber, logEndOffset: .[3]|tonumber, lag: .[4]|tonumber}'


cat consumer-lag-output.log \
    | sed -n "${sed_expr}" \
    | awk "${awk_expr}" \
    | jq "${jq_expr}"
