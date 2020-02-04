#!/usr/bin/env bash

source ./load-environment.sh
index=$ES_INDEX

delete_index() {
    echo "Deleting index '$index'..."
    curl --cacert $ES_CACERT \
         -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
         -XDELETE "https://${ES_HOST}:9200/$index?pretty"
}

if [ "$#" -ne 0 ]; then
    echo "Arguments received, index=$1"
    index=$1
fi

delete_index
