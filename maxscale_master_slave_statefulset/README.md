# MariaDB Kubernetes MaxScale Master Slave using StatefulSets
This directory contains a simple evaluation example showing a Master with 3 Slave cluster fronted by MaxScale. Two StatefulSets are created for MaxScale and the Master/Slave cluster.

## To Run
You must first have a working kubernetes installation. For local standalone installations use minikube for windows / mac or microk8s (linux).

Simply type:
```sh
./create-masterslave-cluster.sh
```

To access the MaxScale node locally, create a port forward (substitute the appropriate pod name in the port forward command):
```sh
kubectl get pod
kubectl port-forward maxscale-d76cbd47c-sjb4t 4006:4006 4008:4008 9195:9195
```
After this:
```
curl http://localhost:9195/metrics
mysql -umaxuser -pmaxpwd -P4006 -h 127.0.0.1
```

The Kubernetes objects can be deleted using:
```sh
./delete-masterslave-cluster.sh
```
