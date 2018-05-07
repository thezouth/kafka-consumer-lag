#!/usr/bin/env bash

#
# Usage: kafka-consumer-lag.sh -i kafka_server -o elasticsearch_url -t <interval_second> group1 [group2 .. groupN]
#
printUsage() {
    echo "Usage: $0 --bootstrap-server <host>[:<port>] --elasticsearch-url <url> [--interval 60] group1 [group2 .. groupN]"
}

#
# Check essential commands for complete the task
#
checkUtilitiesCommand() {
    if [ -z "$KAFKA_HOME" ]; then
        echo "KAFKA_HOME environment variable unset. Please install kafka and define it."
        exit 1
    fi

    CONSUMER_GROUP_CMD="$KAFKA_HOME/bin/kafka-consumer-groups.sh"

    if [ ! -x "$CONSUMER_GROUP_CMD" ]; then
        echo "Permission to execute $CONSUMER_GROUP_CMD was denied. Please allow it to execute."
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
}

#
# Check consumer offset from kafka broker
#
checkConsumerGroupOffset() {
    CONSUMER_GROUP=$1

    SED_EXPR='3,$p'
    AWK_EXPR='BEGIN { printf "["; } { for(i = 1; i < NF; i++) { printf "\"%s\",", $i; } printf "\"%s\"", $i; } END { printf "]\n"; }'
    JQ_EXPR="{consumerGroup: \"$CONSUMER_GROUP\", consumerId: .[5], host: .[6], clientId: .[7], topic: .[0], partition: .[1]|tonumber, currentOffset: .[2]|tonumber, logEndOffset: .[3]|tonumber, lag: .[4]|tonumber}"

    KAFKA_CMD="$CONSUMER_GROUP_CMD --bootstrap-server $BOOTSTRAP_SERVER --describe --group $CONSUMER_GROUP"
    OUTPUT=$($KAFKA_CMD 2>/dev/null)

    if [[ "$OUTPUT" =~ ^(E|e)rror ]]; then
        echo "$OUTPUT"
    else
        echo "$OUTPUT" \
            | sed -n "${SED_EXPR}" \
            | awk "${AWK_EXPR}" \
            | jq "${JQ_EXPR}"
    fi
}

#
# Parse command line arguments
#
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -I|--bootstrap-server)
        BOOTSTRAP_SERVER="$2"
        shift
        shift
        ;;
        -O|--elasticsearch-url)
        output="$2"
        shift
        shift
        ;;
        -t|--interval)
        INTERVAL="$2"
        shift
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done
set -- "${POSITIONAL[@]}"   # restore positional parameters

#
# Validate required command parameters
#
if [ -z "$BOOTSTRAP_SERVER" ]; then
    printUsage
    echo "Error: bootstrap-server parameter was required."
    exit 0
fi

# if [ -z "$output" ]; then
#     printUsage
#     echo "Error: elasticsearch-url parameter was required."
#     exit 0
# fi

INTERVAL=${INTERVAL:-60}

checkUtilitiesCommand

# Main loop to check offset periodically.
while : ; do
    for group in $@ ; do
        checkConsumerGroupOffset $group &
    done
    sleep $INTERVAL
done