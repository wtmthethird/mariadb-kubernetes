#!/usr/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# Starts and initializes a MariaDB master or slave instance
set -ex

# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

# load backup
if [[ ! "$BACKUP_CLAIM_NAME" == "" ]]; then
    MASTER_HOST=$(cat /mnt/config-map/master)
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        chown -R mysql:mysql /backup/$RESTORE_FROM_FOLDER
    fi
fi

if [[ "$CLUSTER_TOPOLOGY" == "standalone" ]] || [[ "$CLUSTER_TOPOLOGY" == "masterslave" ]]; then
    # fire up the instance
    /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync
elif [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
    MASTER_HOST=$(cat /mnt/config-map/master)

    cp /mnt/config-map/galera.cnf /etc/mysql/mariadb.conf.d/galera.cnf

    # fire up the instance
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        /usr/local/bin/docker-entrypoint.sh mysqld  --wsrep-new-cluster --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync
    else
        /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync
    fi
fi