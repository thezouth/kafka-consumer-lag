#!/usr/bin/env bash

printUsage() {
    echo "Usage: $0 --bootstrap-server <host>[:<port>] --elasticsearch-url <url> [--interval 60] group1 [group2 .. groupN]"
}

# Usage: kafka-consumer-lag.sh -i kafka_server -o elasticsearch_url -t <interval_second> group1 [group2 .. groupN]
positional=()
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -I|--bootstrap-server)
        input="$2"
        shift
        shift
        ;;
        -O|--elasticsearch-url)
        output="$2"
        shift
        shift
        ;;
        -t|--interval)
        interval="$2"
        shift
        shift
        ;;
        *)
        positional+=("$1")
        shift
        ;;
    esac
done
set -- "${positional[@]}"   # restore positional parameters

if [ -z "$input" ]; then
    printUsage
    echo "Error: bootstrap-server parameter was required."
    exit 0
fi

# if [ -z "$output" ]; then
#     printUsage
#     echo "Error: elasticsearch-url parameter was required."
#     exit 0
# fi

# default parameters assignment
interval=${interval:-60}


# Check prerequisites utilities command
if [ -z "$KAFKA_HOME" ]; then
    echo "KAFKA_HOME environment variable unset. Please install kafka and define it."
    exit 1
fi

consumer_grp_cmd="$KAFKA_HOME/bin/kafka-consumer-groups.sh"

if [ ! -x "$consumer_grp_cmd" ]; then
    echo "Permission to execute $consumer_grp_cmd was denied. Please allow it to execute."
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

kafka_cmd="$consumer_grp_cmd --bootstrap-server $input --describe --group $1"

sed_expr='3,$p'

awk_expr='BEGIN { printf "["; } { for(i = 1; i < NF; i++) { printf "\"%s\",", $i; } printf "\"%s\"", $i; } END { printf "]\n"; }'

jq_expr="{consumerGroup: \"$1\", consumerId: .[5], host: .[6], clientId: .[7], topic: .[0], partition: .[1]|tonumber, currentOffset: .[2]|tonumber, logEndOffset: .[3]|tonumber, lag: .[4]|tonumber}"

# Execute command and process output
kafka_output=$($kafka_cmd 2>/dev/null)
if [[ "$kafka_output" =~ ^(E|e)rror ]]; then
    echo "$kafka_output"
else
    echo "$kafka_output" \
        | sed -n "${sed_expr}" \
        | awk "${awk_expr}" \
        | jq "${jq_expr}"
fi
