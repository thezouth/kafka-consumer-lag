#!/usr/bin/env bash 

if [ -z "$KAFKA_HOME" ]; then
    echo "KAFKA_HOME environment variable unset. Please install kafka and define it." 
    exit 1 
fi

if [ -z "$(which jq)" ]; then
    echo "jq command needed for operation in script. Please install it."
    exit 1
fi

if [ -z "$(which curl)" ]; then
    echo "curl command needed for operation in script. Please install it."
    exit 1
fi

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
