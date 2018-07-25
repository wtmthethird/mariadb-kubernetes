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
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        # first master run
        mysql_install_db --user=mysql --datadir=/var/lib/mysql

        service mysql start --wsrep-new-cluster
        # fix debian account password
        DEB_PASS=$(grep -i "password" /etc/mysql/debian.cnf | head -1 | awk 'match($0, "^password = (.*)$", m) {print m[1]}')
        mysql -vvv -Bse "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${DEB_PASS}';FLUSH PRIVILEGES;"

        mysql -vvv -Bse "set sql_mode=NO_ENGINE_SUBSTITUTION; GRANT ALL ON *.* to root@'%';FLUSH PRIVILEGES;"
        mysql -vvv -Bse "alter user 'root'@'%' identified by '${MYSQL_PASS}'; FLUSH PRIVILEGES;"
    else
        PING0=$(mysql --host=galera-0.mariadb-cluster -Bse "SELECT 1" -p${MYSQL_PASS}) || PING0=0
        PING1=$(mysql --host=galera-1.mariadb-cluster -Bse "SELECT 1" -p${MYSQL_PASS}) || PING1=0
        PING2=$(mysql --host=galera-2.mariadb-cluster -Bse "SELECT 1" -p${MYSQL_PASS}) || PING2=0

        if [[ $PING0 -eq 1 ]] || [[ $PING1 -eq 1 ]] || [[ $PING2 -eq 1 ]]; then
            service mysql start
        else
            service mysql start --wsrep-new-cluster
        fi
    fi
else
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi
    service mysql start
fi

# don't exit the process
tail -f /dev/null
