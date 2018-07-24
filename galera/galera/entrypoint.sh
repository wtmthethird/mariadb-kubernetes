#!/bin/bash
set -ex

/etc/init.d/ssh start

# fix file permissions for fluentd
touch /var/log/mysql/slow-query.log
chmod 666 /var/log/mysql/slow-query.log
touch /var/log/mysql/error.log
chmod 666 /var/log/mysql/error.log

[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

if [[ $server_id -eq 0 ]]; then
    if [[ ! -f /var/lib/mysql/mysql/multi-master.info ]]; then
        # first master run
        service mysql start --wsrep-new-cluster
        mysql -vvv -Bse "set sql_mode=NO_ENGINE_SUBSTITUTION; GRANT ALL ON *.* to root@'%';FLUSH PRIVILEGES;"
        mysql -vvv -Bse "alter user 'root'@'%' identified by '${MYSQL_PASS}'; FLUSH PRIVILEGES;"
    else
        service mysql start
    fi
else
    service mysql start
fi

# don't exit the process
tail -f /dev/null
