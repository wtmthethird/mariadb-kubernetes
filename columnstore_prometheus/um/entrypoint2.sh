#!/bin/bash

# start the ssh daemon
/usr/sbin/sshd

# start the columnsotre process
/usr/local/mariadb/columnstore/bin/columnstore start

# don't exit the process
tail -f /dev/null