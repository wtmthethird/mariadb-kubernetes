# MariaDB Kubernetes MaxScale Master Slave using StatefulSets (OSX High Sierra)

## Introduction

This directory contains a simple evaluation example showing a Master with 3 Slave cluster fronted by MaxScale. Two StatefulSets are created for MaxScale and the Master/Slave cluster.
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->
<!-- code_chunk_output -->

* [MariaDB Kubernetes MaxScale Master Slave using StatefulSets (OSX High Sierra)](#mariadb-kubernetes-maxscale-master-slave-using-statefulsets-osx-high-sierra)
	* [Introduction](#introduction)
	* [Install Prerequisites on a Mac](#install-prerequisites-on-a-mac)
		* [Install Homebrew](#install-homebrew)
		* [Start Minikube](#start-minikube)
	* [Install MariaDB Kubernetes MaxScale Master Slave Demo](#install-mariadb-kubernetes-maxscale-master-slave-demo)
		* [Get The Demo](#get-the-demo)
		* [Configure the environment](#configure-the-environment)
			* [Swich to the statefulset directory:](#swich-to-the-statefulset-directory)
			* [Prepare a configuration](#prepare-a-configuration)
		* [Check Status](#check-status)
			* [check pod configuration](#check-pod-configuration)
			* [check (and follow) maxadmin (or another pod’s) logs](#check-and-follow-maxadmin-or-another-pods-logs)
	* [Stop and remove the demo.](#stop-and-remove-the-demo)

<!-- /code_chunk_output -->
## Install Prerequisites on a Mac

### Install Homebrew

Homebrew is a external package manager for OSX it is requred for the instalation of some of the components below.(Homebrew is not the only way to install those for more information refer to [Other ways to install k8s](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-with-macports-on-macos)

Open your Terminal app. Press cmd+space and type terminal.app
Type the folowing command in the terminal window.
```$ /usr/bin/ruby -e “$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)”```
This will start Homebrew instalation. 
(it will require Xcode Command Line Tools they will be installed or updated in the process.)

### Install Hypervisor

A hypervisor is required for the Kubectl to work on OSX. the popular options are  VirtualBox or VMware Fusion, or HyperKit.
This guide will do the instalations with VirtualBox

#### VirtualBox

[VirtualBox for OSX](https://download.virtualbox.org/virtualbox/5.2.18/VirtualBox-5.2.18-124319-OSX.dmg)
Download the package above and follow the instructions. OSX my require allowing this package in security & privacy section. 
![](screen1.jpg)

[Other Install Options](https://www.virtualbox.org/wiki/Downloads)

### Install Kubernetes command-line tool(kubectl)

Instalation with brew is simple
Type the following in your teminal window. 
* ```$ brew install kubernetes-cli```

### Install Minikube

Minikube can be installed using the following comand
```curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-darwin-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/```

Additional versions can be found [here](https://github.com/kubernetes/minikube/releases)

### Start Minikube

The minikube can be started using the following comand
` $ minikube start `
To stop the cluster use:
` $ minikube stop `

Start the miniqube now.

## Install MariaDB Kubernetes MaxScale Master Slave Demo

### Get The Demo

Get the creation script from GitHub

`$ git git@github.com:mariadb-corporation/mariadb-kubernetes.git`

Github login might be required for this step.

Switch to the branch:
`$  git checkout master-slave-dynamic-discovery`

### Configure the environment

#### Swich to the statefulset directory:
`$ cd mariadb-kubernetes/`
`$ cd maxscale_master_slave_statefulset/`

#### Prepare a configuration

Replace _app_ and _dev_

_app_ - application name i.e my_first_app, app1 etc.
_dev_ - environment name i.e. dev, test, prod, other

`$ ./create-masterslave-cluster.sh -a _app_ -e _dev_>`

### Check Status
#### check pod configuration
```$ kubectl get pods```

```NAME                   READY     STATUS    RESTARTS   AGE
app-dev-mdb-ms-0    1/1       Running   0          3m
app-dev-mdb-ms-1    1/1       Running   0          3m
app-dev-mdb-ms-2    1/1       Running   0          2m
app-dev-mdb-mxs-0   1/1       Running   0          3m
```
#### check maxadmin output

```$ kubectl exec alex-devel-mdb-mxs-0 -- maxadmin list servers```
#### check (and follow) maxadmin (or another pod’s) logs
```$ kubectl logs alex-devel-mdb-mxs-0 -f```

#### minikube dashboard
presents graphical interface showing the statuses of all kubernetes objects.
```$ minikube dashboard ```

## Stop and remove the demo.
TODO: Uninstalation steps


