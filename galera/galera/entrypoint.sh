#!/bin/bash

/etc/init.d/ssh start

# service mysql stop

if [ "$MAIN_NODE" = true ] ; then
    service mysql bootstrap
    mysql -vvv -Bse  "set sql_mode=NO_ENGINE_SUBSTITUTION; GRANT ALL ON *.* to root@'%';FLUSH PRIVILEGES;"
    echo MAIN NODE INITIALIZED
else
    service mysql start
    echo SECONDARY NODE INITIALIZED
fi

# don't exit the process
tail -f /dev/null