#!/usr/bin/env bash

source ./load-environment.sh

curl --cacert $ES_CACERT \
  -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
  -H "Content-Type: application/json" \
  -XPUT "https://${ES_HOST}:9200/_template/template_1?pretty" \
  -d @resources/template1.json
