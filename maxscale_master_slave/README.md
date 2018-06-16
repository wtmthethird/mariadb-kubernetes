# MariaDB Kubernetes MaxScale Master Slave Example
This directory contains a simple evalation example showing a Master with 2 Slave cluster fronted by MaxScale.

## To Run
You must first have a working kubernetes installation. For local standalone installations use minikube for windows / mac or microk8s (linux).

Simply type:
```sh
./create_configmaps.sh
kubectl create -f master.yaml
kubectl create -f slave1.yaml
kubectl create -f slave2.yaml
kubectl create -f maxscale.yaml
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
