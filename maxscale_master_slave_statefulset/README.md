# MariaDB Kubernetes MaxScale Master Slave using StatefulSets
<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

* [Overview](#overview)
* [Installing microk8s on Linux](#installing-microk8s-on-linux)
* [Installing minikube on Windows 10 Professional with Hyper-V](#installing-minikube-on-windows-10-professional-with-hyper-v)
* [Installing minikube on MacOS X (High Sierra)](#installing-minikube-on-macos-x-high-sierra)
	* [Install Homebrew](#install-homebrew)
	* [Install Minikube](#install-minikube)
	* [Start Minikube](#start-minikube)
* [Running a Master/Slave cluster](#running-a-masterslave-cluster)
	* [Linux and OSX](#linux-and-osx)
	* [Windows](#windows)
* [Cleaning up a Master/Slave cluster](#cleaning-up-a-masterslave-cluster)

## Overview
This directory contains kubernetes stateful set scripts to install a 3 node master slave cluster fronted by an Active/Passive pair of MaxScale nodes. The cluster can be deployed using helm or alternatively using shell / powershell kubectl wrapper scripts. The scripts should be considered alpha quality at this stage and should not be used for production deployments.

## Local Kubernetes installations
The scripts can be deployed against a cloud kubernetes deployment such as Google Kubernetes Engine or alternatively using one of several local vm based kubernetes frameworks such as minikube for Windows and Mac or microk8s for Ubuntu / Linux.

### Installing microk8s on Ubuntu
**microk8s** is a lightweight kubernetes install that can be installed using the cross platform snap utility but most optimally on Ubuntu.

The following steps will install microk8s and configure it for dns, dashboard, and storage:

```sh
sudo snap install microk8s --beta --classic
microk8s.enable dns dashboard storage
```

After installation the kubernetes dashboard application may be accessed at:
http://localhost:8080/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy

### Installing minikube on Windows 10
- If you are running Windows 10 Professional enable Hyper-V virtualization. For other versions install VirtualBox as the virtualization software.
- Download minikube for windows from: https://github.com/kubernetes/minikube/releases and rename to minikube.exe and add to a directory in your path.
- Similarly download kubectl and add to the same directory, using the latest link here: https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-binary-using-curl
- If you are utilizing Hyper-V, create an external switch in hyper-v virtual switch manager named ExternalSwitch configured to use external networking.

To initialize minikube for VirtualBox:
```sh
minikube start
```

To initialize minikube for Hyper-V:
```sh
minikube start --vm-driver hyperv --hyperv-virtual-switch "ExternalSwitch"
```

After installation the kubernetes dashboard application may be accessed by running:
```sh
minikube dashboard
```

### Installing minikube on MacOS X (High Sierra)

#### Install Homebrew

Homebrew is a external package manager for OSX it is required for the installation of some of the components below.(Homebrew is not the only way to install those for more information refer to [Other ways to install k8s](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-macports-on-macos)

Open your Terminal app. Press cmd+space and type terminal.app

Type the following command in the terminal window.

```$ /usr/bin/ruby -e “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”```

This will start Homebrew installation (Xcode Command Line Tools are a dependency which will be installed or updated in the process).

#### Install Hypervisor

A hypervisor is required for the Kubectl to work on OSX. the popular options are  VirtualBox or VMware Fusion, or HyperKit. This guide will do the installations with VirtualBox

##### VirtualBox

Download the [VirtualBox for OSX](https://download.virtualbox.org/virtualbox/5.2.18/VirtualBox-5.2.18-124319-OSX.dmg) package and follow the instructions. OSX may require allowing this package in security & privacy section.

![](screen1.jpg)

[Other Install Options](https://www.virtualbox.org/wiki/Downloads)

#### Install Kubernetes command-line tool (kubectl)

Install kubectl by typing the following Homebrew command in a teminal window.

```$ brew install kubernetes-cli```

#### Install Minikube

Install minikube by typing the following Homebrew command in a terminal window.

```bash
curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/
```

You can also use another version of [minikube](https://github.com/kubernetes/minikube/releases).

#### Start Minikube

Minikube can be started using the following command

```bash
$ minikube start
```

To stop the cluster use:

```
$ minikube stop
```

## Running the Master/Slave plus MaxScale cluster

### Installing the Cluster with Helm
Helm provides a simple means of installation and is the recommended approach. First install and configure helm for your platform (https://github.com/helm/helm/releases) and cluster then simply run choosing an appropriate id value to uniquely identify your cluster:
```
$ helm install . --name <id>
```

To review installed releases:
```
$ helm list
```

To remove a helm release:
```
$ helm helm delete <id>
```


### Installing the Cluster with shell scripts on Linux and Mac

For Linux and Mac systems type the following in a shell to install the cluster:
```sh
./create-masterslave-cluster.sh -a <app> -e <env>
```
To remove the cluster:
```sh
./delete-masterslave-cluster.sh -a <app> -e <env>
```


### Windows
For Windows type the following in PowerShell:
```sh
./create-masterslave-cluster.ps1 -a <app> -e <env>
```
To remove the cluster:
```sh
./delete-masterslave-cluster.ps1 -a <app> -e <env>
```

## Using the cluster
To access the MaxScale node locally, create a port forward (substitute the appropriate pod name in the port forward command):
```sh
kubectl get pod
kubectl port-forward maxscale-d76cbd47c-sjb4t 4006:4006 4008:4008 8003:8003
```
The following ports are mapped to the local host:
- 4006: MaxScale ReadWrite Listener
- 4008: MaxScale ReadOnly Listener
- 8003: MaxScale REST API
After this:
```
curl http://localhost:9195/metrics
mysql -umaxuser -pmaxpwd -P4006 -h 127.0.0.1
mysql -umaxuser -pmaxpwd -P4008 -h 127.0.0.1
```
