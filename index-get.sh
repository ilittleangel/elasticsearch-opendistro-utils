#!/usr/bin/env bash

source ./load-environment.sh
filter=*

if [ "$#" -gt 0 ]; then
    echo "Index filter received!"
    filter=$1*
fi

curl --cacert $ES_CACERT \
    -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
    -XGET "https://${ES_HOST}:9200/_cat/indices/$filter?v&s=index&pretty"
