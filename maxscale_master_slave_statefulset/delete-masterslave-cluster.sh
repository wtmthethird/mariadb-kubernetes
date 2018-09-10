#!/bin/bash
# Copyright (C) 2018 MariaDB Corporation
# Destroys templatized master-slave cluster fronted by MaxScale in Kubernetes
# User-defined parameters are "application" and "environment"


function print_usage() {
    echo "Usage: "
    echo "master-slave-cluster.sh -a <application> -e <environment> [<options>]"
    echo ""
    echo "Required options: "
    echo "         -a <application name>"
    echo "         -e <environment name>"
    echo ""
    echo "All <application name>-<environment name> will be removed"
    echo ""
    exit 1
}

function parse_options() {
    APP=""
    ENV=""
    DBUSER="admin"
    DBPWD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    REPLUSER="repl"
    REPLPWD=$(cat /dev/urandom | env LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    DRY_RUN=""

    while [[ $# -gt 0 ]]
    do

    key="$1"
    case $key in
        (-a|--app)
        APP="$2"
        shift
        shift
        ;;
        (-e|--env)
        ENV="$2"
        shift
        shift
        ;;
        (-u|--db-user)
        DBUSER="$2"
        shift
        shift
        ;;
        (-p|--db-pass)
        DBPWD="$2"
        shift
        shift
        ;;
        (--dry-run)
        DRY_RUN="--dry-run -o yaml"
        shift
        ;;
        (-h|*)
        print_usage
        ;;
    esac
    done

    if [[ -z "$APP" ]]; then
       print_usage
    fi

    if [[ -z "$ENV" ]]; then
       print_usage
    fi
}


parse_options "$@"

echo "delete statefulset $APP-$ENV-mdb-ms  $APP-$ENV-mdb-mxs ..."
kubectl delete statefulset $APP-$ENV-mdb-ms  $APP-$ENV-mdb-mxs
echo "delete service $APP-$ENV-mariadb  $APP-$ENV-mdb-clust ..."
kubectl delete service $APP-$ENV-mariadb  $APP-$ENV-mdb-clust
echo "delete secret $APP-$ENV-mariadb-secret ..."
kubectl delete secret $APP-$ENV-mariadb-secret
echo "delete configmap mariadb-config ..."
kubectl delete configmap mariadb-config
echo "Done."