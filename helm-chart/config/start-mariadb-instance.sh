#!/usr/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# Starts and initializes a MariaDB master or slave instance
set -ex

# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

{{ if or (eq .Values.TEMPLATE "standalone") (eq .Values.TEMPLATE "masterslave") }}
    # fire up the instance
    /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync
{{ else if eq .Values.TEMPLATE "galera" }}
    MASTER_HOST=$(cat /mnt/config-map/master)

    cp /mnt/config-map/galera.cnf /etc/mysql/mariadb.conf.d/galera.cnf

    # fire up the instance
    if [[ "$MASTER_HOST" == "localhost" ]]; then
        /usr/local/bin/docker-entrypoint.sh mysqld  --wsrep-new-cluster --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync
    else
        # rm -f /var/lib/mysql/galera.cache
        # rm -f /var/lib/mysql/grastate.dat
        # rm -f /var/lib/mysql/gvwstate.dat
        /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1 --innodb-flush-method=fsync
    fi
{{ end }}