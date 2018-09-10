# MariaDB Kubernetes Single Node Columnstore with Zeppelin and Sandbox Data
This directory contains a simple evaluation example showing a single columnstore with sandbox data. Two StatefulSets are created for Columnstore and the Zeppelin front end.

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
./create-single-node.sh -a myapp -e dev
```

For windows type the following in powershell:
```sh
./create-single-node.ps1 -a myapp -e dev
```

To access the Zeppelin node locally, create a port forward (substitute the appropriate pod name in the port forward command):
```sh
kubectl port-forward buff-dev-mdb-zepp-0  8080 8080
```
After this:
[http://localhost:8080](http://localhost:8080)

The Kubernetes objects can be deleted using:
```sh
./delete-single-node.sh -a app -e dev
```
