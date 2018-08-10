# (C) 2018 MariaDB Corporation
# Deletes a templatized master-slave cluster fronted by MaxScale in Kubernetes
# User-defined parameters are "application" and "environment"

param (
    [Parameter(Mandatory=$true,HelpMessage="Application Name")][string]$a,
    [Parameter(Mandatory=$true,HelpMessage="Environment Name")][string]$e
 )

kubectl delete statefulset $a-$e-mdb-ms  $a-$e-mdb-mxs
kubectl delete service $a-$e-mariadb  $a-$e-mdb-clust
kubectl delete secret $a-$e-mariadb-secret
kubectl delete configmap mariadb-config
