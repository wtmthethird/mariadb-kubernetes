#!/bin/bash

/etc/init.d/ssh start

if [ "$MAIN_NODE" = true ] ; then
    service mysql start --wsrep-new-cluster
    mysql -vvv -Bse "set sql_mode=NO_ENGINE_SUBSTITUTION; GRANT ALL ON *.* to root@'%';FLUSH PRIVILEGES;"
    mysql -vvv -Bse "alter user 'root'@'%' identified by '${MYSQL_PASS}'; FLUSH PRIVILEGES;"
else
    service mysql start
fi

# don't exit the process
tail -f /dev/null