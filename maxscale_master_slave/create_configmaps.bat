kubectl create configmap maxscale-cfg --from-file=./config/maxscale/maxscale.cnf
kubectl create configmap master-cfg --from-file=./config/master/users.sql
kubectl create configmap slave-cfg --from-file=./config/slave/replication.sql
