#!/usr/bin/bash
set -ex

[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

ls -l /var/lib/mysql
          
if [[ $server_id -eq 0 ]]; then
   if [[ ! -d /var/lib/mysql/mysql ]]; then
      # first run on master, ensure maxscale user is initialized
      cp /mnt/config-map/users.sql /docker-entrypoint-initdb.d
   fi 
   /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id))
else
   if [[ ! -d /var/lib/mysql/mysql ]]; then
       # first run on slave, ensure replication is set up  
       cp /mnt/config-map/replication.sql /docker-entrypoint-initdb.d
   fi
   /usr/local/bin/docker-entrypoint.sh mysqld --log-bin=mariadb-bin --binlog-format=ROW --server-id=$((3000 + $server_id))
fi
