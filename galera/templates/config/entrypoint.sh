#!/bin/bash
set -ex

/etc/init.d/ssh start

[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"

MASTER_HOST=$(perl /register-instance-pkg.pl $DB_HOST http {{APPLICATION}}-{{ENVIRONMENT}}-maxscale-0.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust 8989 admin mariadb)

if [[ $server_id -eq 0 ]]; then
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        # fix file permissions for fluentd
        touch /var/log/mysql/slow-query.log
        chmod 666 /var/log/mysql/slow-query.log
        touch /var/log/mysql/error.log
        chmod 666 /var/log/mysql/error.log

        cp /mdb-config/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

        # init database
        mysql_install_db --user=mysql --datadir=/var/lib/mysql

        # start mysql and create new cluster
        service mysql start --wsrep-new-cluster

        # fix debian account password
        DEBIAN_PASS=$(grep -i "password" /etc/mysql/debian.cnf | head -1 | awk 'match($0, "^password = (.*)$", m) {print m[1]}')
        mysql -vvv -Bse "GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '${DEBIAN_PASS}';FLUSH PRIVILEGES;"

        # create replication (maxscale) and admin users
        mysql -vvv -Bse "CREATE USER '{{REPLICATION_USERNAME}}'@'127.0.0.1' IDENTIFIED BY '{{REPLICATION_PASSWORD}}';"
        mysql -vvv -Bse "CREATE USER '{{REPLICATION_USERNAME}}'@'%' IDENTIFIED BY '{{REPLICATION_PASSWORD}}';"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{REPLICATION_USERNAME}}'@'127.0.0.1' WITH GRANT OPTION;"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{REPLICATION_USERNAME}}'@'%' WITH GRANT OPTION;"

        mysql -vvv -Bse "CREATE USER '{{ADMIN_USERNAME}}'@'127.0.0.1' IDENTIFIED BY '{{ADMIN_PASSWORD}}';"
        mysql -vvv -Bse "CREATE USER '{{ADMIN_USERNAME}}'@'%' IDENTIFIED BY '{{ADMIN_PASSWORD}}';"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{ADMIN_USERNAME}}'@'127.0.0.1' WITH GRANT OPTION;"
        mysql -vvv -Bse "GRANT ALL ON *.* TO '{{ADMIN_USERNAME}}'@'%' WITH GRANT OPTION;"

        mysql -vvv -Bse "FLUSH PRIVILEGES;"
    else
        COUNTER=1
        until [[ $COUNTER -gt 9 ]] || [[ $(mysql --host={{APPLICATION}}-{{ENVIRONMENT}}-galera-$COUNTER.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust -Bse "SELECT 1" -u{{ADMIN_USERNAME}} -p{{ADMIN_PASSWORD}}) -eq 1 ]]; do
            let COUNTER+=1
        done

        if [[ $COUNTER -gt 9 ]]; then
            # no cluster is active, start a fresh new one
            rm -f /var/lib/mysql/galera.cache
            rm -f /var/lib/mysql/grastate.dat
            rm -f /var/lib/mysql/gvwstate.dat
            service mysql start --wsrep-new-cluster
        else
            # join existing cluster
            sed -r "s/{{APPLICATION}}-{{ENVIRONMENT}}-galera-0\.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust/{{APPLICATION}}-{{ENVIRONMENT}}-galera-$COUNTER.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust/" /mdb-config/50-server.cnf > /etc/mysql/mariadb.conf.d/50-server.cnf
            service mysql start
        fi
    fi
else
    
    if [[ ! -d /var/lib/mysql/mysql ]]; then
        # fix file permissions for fluentd
        touch /var/log/mysql/slow-query.log
        chmod 666 /var/log/mysql/slow-query.log
        touch /var/log/mysql/error.log
        chmod 666 /var/log/mysql/error.log

        # init database
        mysql_install_db --user=mysql --datadir=/var/lib/mysql
    fi

    COUNTER=0
    until [[ $COUNTER -gt 9 ]] || [[ $(mysql --host={{APPLICATION}}-{{ENVIRONMENT}}-galera-$COUNTER.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust -Bse  "SELECT 1" -u{{ADMIN_USERNAME}} -p{{ADMIN_PASSWORD}}) -eq 1 ]]; do
        let COUNTER+=1
    done
    sed -r "s/{{APPLICATION}}-{{ENVIRONMENT}}-galera-0\.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust/{{APPLICATION}}-{{ENVIRONMENT}}-galera-$COUNTER.{{APPLICATION}}-{{ENVIRONMENT}}-mdb-clust/" /mdb-config/50-server.cnf > /etc/mysql/mariadb.conf.d/50-server.cnf

    # start mysql
    service mysql start
fi

# don't exit the process
tail -f /dev/null
