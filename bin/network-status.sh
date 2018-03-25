#!/usr/bin/env bash

if docker network inspect ${COMPOSE_PROJECT_NAME}_network > /dev/null; then
    DATA=$(docker network inspect ${COMPOSE_PROJECT_NAME}_network)

    NETWORK_NAME=$(echo $DATA | python -c 'import json,sys; data = json.load(sys.stdin); print (data[0]["Name"]);')
    NETWORK_SUBNET=$(echo $DATA | python -c 'import json,sys; data = json.load(sys.stdin); print (data[0]["IPAM"]["Config"][0]["Subnet"]);')
    I=0
    CONTAINERS_NUMBER=$(echo $DATA | python -c 'import json,sys; data = json.load(sys.stdin); print (len(data[0]["Containers"].items()));')
    ( \
    echo "Container name * Container IPv4 address"; \
    while [ "$I" -lt "$CONTAINERS_NUMBER" ]; do \
        CONTAINER=$(echo $DATA | python -c 'import json,sys; data = json.load(sys.stdin); print (list(data[0]["Containers"])['$I'])')
        echo $DATA | python -c 'import json,sys; data = json.load(sys.stdin); print (data[0]["Containers"]["'$CONTAINER'"]["Name"] + " * " + data[0]["Containers"]["'$CONTAINER'"]["IPv4Address"]);'; \
        I=$((I+1)); \
    done ) | column -t -s "*"
else
    echo -ne "${COMPOSE_PROJECT_NAME}_network is not running\n"
fi
