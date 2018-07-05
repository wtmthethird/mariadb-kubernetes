#!/bin/sh
set -ex

# get directory of script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# delete the stateful sets in reverse order 
kubectl delete -f "$DIR/maxscale.yaml"
kubectl delete -f "$DIR/masterslave.yaml"

# delete the configuration maps 
kubectl delete configmap mariadb-masterslave-config
kubectl delete configmap mariadb-maxscale-config

# delete the volume claims 
for i in [0..2]; do
	kubectl delete pvc mariadb-data-vol-mariadb-masterslave-0
done 

# done