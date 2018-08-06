#!/bin/bash
set -ex

# start ssh daemon
/usr/sbin/sshd

[[ $(hostname) =~ -([0-9]+)$ ]] || exit 1
server_id=${BASH_REMATCH[1]}

if [[ $server_id -eq 2 ]]; then
    sleep 5
    
    export USER=root
    OWN_ADDRESS=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
    /usr/sbin/sshd

    # postConfigure with input passed in
    /bin/echo -e "2\n1\n\n\ncolumnstore-1\n\n1\ncolumnstore-0.mariadb-columnstore\n\n\n2\ncolumnstore-2.mariadb-columnstore\n$OWN_ADDRESS\n\n\ncolumnstore-1.mariadb-columnstore\n\n\n2\n\n\n" | /usr/local/mariadb/columnstore/bin/postConfigure -n

    # update root user to allow external connection, need to turn off NO_AUTO_CREATE_USER. 
    ssh -vvv -o "StrictHostKeyChecking=no" -l root columnstore-0.mariadb-columnstore '/usr/local/mariadb/columnstore/mysql/bin/mysql --defaults-file=/usr/local/mariadb/columnstore/mysql/my.cnf -uroot -vvv -Bse "set sql_mode=NO_ENGINE_SUBSTITUTION;GRANT ALL ON *.* to root@'"'"'%'"'"';FLUSH PRIVILEGES;"'
else
    # start the columnsotre process
    /usr/local/mariadb/columnstore/bin/columnstore start
fi

tail -f /dev/null
