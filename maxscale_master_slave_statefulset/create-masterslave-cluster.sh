#!/bin/sh
set -ex

# get directory of script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# create configmaps for the configurations of the two types of service
kubectl create configmap mariadb-masterslave-config --from-file="$DIR/masterslave-config/"
kubectl create configmap mariadb-maxscale-config --from-file="$DIR/maxscale-config/"

# create the master/slave cluster as a stateful set (including service definitions)
kubectl create -f "$DIR/masterslave.yaml"

# wait for last slave pod to be ready
# TODO replace with kubectl wait 
until kubectl exec mariadb-masterslave-2 -- mysql -h 127.0.0.1 -e "SELECT 1"
do
  sleep 5
done

# all mariadb servers are available, create maxscale instance
kubectl create -f "$DIR/maxscale.yaml"

# done
