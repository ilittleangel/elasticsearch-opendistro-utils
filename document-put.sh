#!/usr/bin/env bash

source ./load-environment.sh
likes=0
post_date=$(date '+%Y-%m-%dT%T.%3NZ')

prepare_doc() {
    echo "Preparing document.json.."
    mkdir -p tmp
    cat resources/document.json > tmp/document.json
    sed -i "s/\"\$post_date/${post_date}/g" tmp/document.json
    sed -i "s/\"\$likes\"/${likes}/g" tmp/document.json
}

index() {
    echo "Indexing document into 'index=${ES_INDEX}'..."
    curl -v --cacert $ES_CACERT \
         -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
         -H "Content-Type: application/json" \
         -XPOST "https://${ES_HOST}:9200/${ES_INDEX}/_doc?pretty" \
         -d @tmp/document.json
}

clean() {
    echo "Cleaning tmp files.. "
    rm -rf tmp
}

if [ "$#" -ne 0 ]; then
    echo "Arguments received, likes=$1"
    likes=$1
fi

prepare_doc
index
clean
