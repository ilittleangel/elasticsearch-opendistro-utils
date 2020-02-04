#!/usr/bin/env bash

source ./load-environment.sh
doc_id=$1

index() {
    echo "Deleting document $1..."
    curl --cacert $ES_CACERT \
         -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
         -XDELETE "https://${ES_HOST}:9200/${ES_INDEX}/_doc/$1?pretty"
}

check_argument() {
    if [ "$#" -ne 1 ]; then
        echo "No document ID received!"
        exit 1
    fi
}

check_argument
delete_document $doc_id
