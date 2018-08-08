# MariaDB Kubernetes MaxScale Master Slave using StatefulSets
This directory contains a simple evaluation example showing a Master with 3 Slave cluster fronted by MaxScale. Two StatefulSets are created for MaxScale and the Master/Slave cluster.

## Installing microk8s
Microk8s is a lightweight kubernetes install that can be installed using the cross
platform snap utility, however it is best run on ubuntu distributions.
```sh
sudo snap install microk8s --beta --classic
microk8s.enable dns dashboard storage
```

After installation the kubernetes dashboard application may be accessed at:
http://localhost:8080/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

## Installing minikube on Windows 10 Professional with Hyper-V
- Download minikube for windows from: https://github.com/kubernetes/minikube/releases and rename to minikube.exe and add to a directory in your path.
- Similarly download kubectl and add to the same directory: https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/windows/amd64/kubectl.exe
- Create an external switch in hyper-v virtual switch manager named ExternalSwitch configured to use external networking.

Now initialize minikube:
```sh
minikube start --vm-driver hyperv --hyperv-virtual-switch "ExternalSwitch"
```

After installation the kubernetes dashboard application may be accessed by running:
```sh
minikube dashboard
```

## To Run
You must first have a working kubernetes installation. For local standalone installations use minikube for windows / mac or microk8s (linux).


For Linux and Mac systems type the following in a shell :
```sh
./create-masterslave-cluster.sh -a myapp -e dev
```

For windows type the following in powershell:
```sh
./create-masterslave-cluster.ps1 -a myapp -e dev
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
