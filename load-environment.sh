#!/usr/bin/env bash

load_environment() {
    source ./env/environment.env
    case $env in
        PRE|pre)
            source ./env/elasticsearch-pre.env
            ;;
        PRO|pro)
            source ./env/elasticsearch-pro.env
            ;;
        LOCAL|local)
            source ./env/elasticsearch-local.env
            ;;
        *)
            echo "Environment $env does not exits"
            exit 1
            ;;
    esac

    echo "$env environment loaded!"
    echo ""
    echo "ES_HOST=$ES_HOST"
    echo "ES_USER=$ES_USER"
    echo "ES_PASS=$ES_PASS"
    echo "ES_INDEX=$ES_INDEX"
    echo "ES_CACERT=$ES_CACERT"
    echo ""
}

load_environment