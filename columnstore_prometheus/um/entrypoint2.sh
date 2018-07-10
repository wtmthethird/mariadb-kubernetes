#!/bin/bash

# start the ssh daemon
/usr/sbin/sshd

# start node exporter
/node_exporter/node_exporter > /dev/null 2>&1 &

# start the columnsotre process
/usr/local/mariadb/columnstore/bin/columnstore start

# don't exit the process
tail -f /dev/null