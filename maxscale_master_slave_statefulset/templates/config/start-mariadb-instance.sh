#!/usr/bin/bash
#
# 2018 (C) MariaDB Corporation
# 
# This scripts starts and initializes a MariaDB master or slave instance
set -ex

# get server id from hostname, it will have the format <something>-<id>
[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

# check if we already are attached to DB storage
if [[ ! -d /var/lib/mysql/mysql ]]; then
   if [[ "{{MASTER_HOST}}" == "NO MASTER" ]]; then
      # this is the master and it's the first run, ensure maxscale user is initialized
      cp /mnt/config-map/users.sql /docker-entrypoint-initdb.d
   else
      # a first run on a slave
      cp /mnt/config-map/replication.sql /docker-entrypoint-initdb.d
   fi
fi

# fire up the instance
/usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id))
