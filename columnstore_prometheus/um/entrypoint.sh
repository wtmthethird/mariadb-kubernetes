#!/bin/bash

# start the columnstore install
/install/postCfg2.sh "2\n1\n\n\ncolumnstore-1\n\n1\nmariadb-cs-um\n\n\n2\nmariadb-cs-pm1\n\n\n\nmariadb-cs-pm2\n\n\n2\n\n\n"

# start the columnstore install
# for docker-compose
# /install/postCfg2.sh "2\n1\n\n\ncolumnstore-1\n\n1\nmariadb-cs-um\n${UM_NODE_IP}\n\n2\nmariadb-cs-pm1\n${PM1_NODE_IP}\n\n\nmariadb-cs-pm2\n${PM2_NODE_IP}\n\n2\n\n\n"

