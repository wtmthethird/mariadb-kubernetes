#!/bin/bash
# (C) 2018 MariaDB Corporation
# Deletes a templatized single-node cluster from Kubernetes
# User-defined parameters are "application" and "environment"

function print_usage() {
    echo "Usage: "
    echo "delete-single-node.sh -a <application> -e <environment> [<options>]"
    echo ""
    echo "Required options: "
    echo "         -a <application name>"
    echo "         -e <environment name>"
    echo ""
    echo "<application name>-<environment name> objects will be removed from kubernetes"
    echo "Supported options: "
    echo "         --cleanup Removes all kubernetes objects"
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
        (--cleanup)
        CLEANUP=1
        shift
        shift
        ;;
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
        (-h|*)
        print_usage
        ;;

    esac
    done
    if [[ 1 -ne "$CLEANUP" ]]; then
        if [[ -z "$APP" ]]; then
        print_usage
        fi

        if [[ -z "$ENV" ]]; then
        print_usage
        fi
    fi
}


parse_options "$@"
if [[ 1 -eq "$CLEANUP" ]]; then
   echo "kubectl delete daemonsets,replicasets,services,deployments,pods,rc,secrets --all"
   kubectl delete daemonsets,replicasets,services,deployments,pods,rc,secrets,statefulsets --all
else
    echo "delete statefulset $APP-$ENV-mdb-sn ..." 
    kubectl delete statefulset $APP-$ENV-mdb-sn 
    echo "delete service $APP-$ENV-mariadb  $APP-$ENV-mdb-clust ..."
    kubectl delete service $APP-$ENV-mariadb  $APP-$ENV-mdb-clust
    echo "delete secret $APP-$ENV-mariadb-secret ..."
    kubectl delete secret $APP-$ENV-mariadb-secret
    echo "delete configmap mariadb-config ..."
    kubectl delete configmap mariadb-config
    echo "Done."
fi

