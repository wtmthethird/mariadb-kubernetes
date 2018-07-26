# Configuration

## Prerequisites

A properly configured Kubernetes environment is needed to run these deployments. The easiest way to do it is to install `minikube` and `kubectl`. Minikube requires a virtualization hypervisor (for example VirtualBox). More information can be found [here](https://kubernetes.io/docs/tasks/tools/install-minikube/).

## Starting minikube

Run `minikube start` to start the Kubernetes VM. Run `minikube status` to check if it is running correctly. You can use `minikube stop` to stop the VM or `minikube delete` to delete it (WARNING: this will delete all currently running pods, volumes, configurations, cached images, etc.)

## Create ConfigMaps

We need to inject the apropriate configuration files for the prometheus and fluentd iamges. To do this, run  
`kubectl create configmap fluentd-config-tx --from-file=fluentd/fluent.conf`  
and  
`kubectl create configmap prometheus-config --from-file=prometheus/prometheus.yml`  
You can run  
`kubectl get configmaps`  
to get a list of all currently installed configmaps and  
`kubectl describe configmaps <configmap_name>`  
to view the details of the specific configmap. Note that changing the files used to create a configmap will not change the already created configmap, thus, if you want to change something you need to first delete the config maps with  
`kubectl delete configmaps <configmap_name>`  
and then recreate it.

## Start Prometheus

Now we can start the Prometheus image.  
`kubectl create -f prometheus.yaml`  
You can run  
`kubectl port-forward prometheus-0 9090`  
for an easy way to connect to it. This will expose Prometheus on [http://localhost:9090](http://localhost:9090)

## Start the Galera cluster

Run  
`kubectl create -f galera.yaml`  
to start the cluster. You can use  
`kubectl get pods`  
and  
`kubectl logs <pod_name> <container_name>` (for example `kubectl logs galera-0 fluentd`)  
to follow the progress.  
When all 3 pods are in status `Running`, to get a terminal into the container, you can run someting like  
`kubectl exec -it <pod_name> -- /bin/bash`  
or  
`kubectl exec -it <pod_name> --container=<container_name> -- sh`  
The `--container=<container_name>` parameter is only needed when the pod has more than one container. Some containers have `bash`, while others only have `sh`.  
You can delete the whole cluster with  
`kubectl delete -f galera.yaml`  
You can delete a single pod with  
`kubectl delete pods <pod_name>`  
Single pods will get recreated according to the statefulset policy.  
Note that the Mariadb/MySQL data is writtent to a persistent volume that will not get deleted with the cluster or pods.

## Start Maxscale

Run  
`kubectl create -f maxscale.yaml`