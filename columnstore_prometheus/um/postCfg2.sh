#!/bin/sh
export USER=root

# postConfigure with input passed in
/bin/echo -e "$1" | /usr/local/mariadb/columnstore/bin/postConfigure -n

# update root user to allow external connection, need to turn off NO_AUTO_CREATE_USER. 
ssh -vvv -o "StrictHostKeyChecking=no" -l root mariadb-cs-um '/usr/local/mariadb/columnstore/mysql/bin/mysql --defaults-file=/usr/local/mariadb/columnstore/mysql/my.cnf -uroot -vvv -Bse "set sql_mode=NO_ENGINE_SUBSTITUTION;GRANT ALL ON *.* to root@'"'"'%'"'"';FLUSH PRIVILEGES;"'

# for docker-compose
# ssh -vvv -o "StrictHostKeyChecking=no" -l root ${UM_NODE_IP} '/usr/local/mariadb/columnstore/mysql/bin/mysql --defaults-file=/usr/local/mariadb/columnstore/mysql/my.cnf -uroot -vvv -Bse "set sql_mode=NO_ENGINE_SUBSTITUTION;GRANT ALL ON *.* to root@'"'"'%'"'"';FLUSH PRIVILEGES;"'

# don't exit the process
tail -f /dev/null
