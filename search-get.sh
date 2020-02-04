#!/usr/bin/env bash

source ./load-environment.sh

curl --cacert $ES_CACERT \
  -H "Authorization: Basic $(echo -n ${ES_USER}:${ES_PASS} | base64)" \
  -H "Content-Type: application/json" \
  -XGET "https://${ES_HOST}:9200/twitter*/_search?pretty&pretty" -d '{
  "query": {
    "bool": {
      "filter": {
        "bool": {
          "must": [
            {
              "range": {
                "post_date": {
                  "time_zone": "+01:00",
                  "gte" : "now-1d",
                  "lt" :  "now"
                }
              }
            },
            {
              "term": {
                "location": "Madrid"
              }
            },
            {
              "term": {
                "hashtags.keyword": "#snowboard"
              }
            },
            {
              "range": {
                "likes": {
                  "gt": 0
                }
              }
            }
          ]
        }
      }
    }
  },
  "sort": [
    {
      "post_date": {
        "order": "asc"
      }
    }
  ]
}'
