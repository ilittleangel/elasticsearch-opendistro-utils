#!/usr/bin/env bash

source ./load-environment.sh

curl --cacert $ES_CACERT \
    -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
    -XGET "https://${ES_HOST}:9200/${ES_INDEX}/_mapping?pretty"
