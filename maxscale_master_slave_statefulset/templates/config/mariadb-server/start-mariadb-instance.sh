#!/usr/bin/bash
#
# Copyright (C) 2018, MariaDB Corporation
# 
# Starts and initializes a MariaDB master or slave instance
set -ex

# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

# fire up the instance
/usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id)) --log-slave-updates=1 --gtid-strict-mode=1
