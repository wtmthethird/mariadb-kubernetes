#!/bin/sh
# 2018 (C) MariaDB Corporation
# This script customizes templates based on the parameters passed to a command-line tool
# the path to the target directory needs to be passed as first argument
echo "----------------------------"
echo "Start init-configurations.sh"
echo "----------------------------"

function expand_templates() {
    sed -e "s/{{MASTER_HOST}}/$MASTER_HOST/g" \
        -e "s/{{APPLICATION}}/$APPLICATION/g" \
        -e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{ADMIN_USER}}/$ADMIN_USER/g" \
        -e "s/{{ADMIN_PASSWORD}}/$ADMIN_PWD/g" \
        -e "s/{{ZEPPELIN_USER}}/$ZEPP_USER/g" \
        -e "s/{{ZEPPELIN_PASSWORD}}/$ZEPP_PWD/g" \
        $1
}

set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
ZEPP_USER=$(cat /mnt/secrets/zepp-username)
ZEPP_PWD=$(cat /mnt/secrets/zepp-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"

expand_templates /mnt/config-template/users.sql > /docker-entrypoint-initdb.d/init.sql
cp /mnt/config-template/start-mariadb-instance.sh /mnt/config-map/start-mariadb-instance.sh
#cp /mnt/config-template/start-mariadb-instance-zepp.sh /mnt/config-map/start-mariadb-instance-zepp.sh
cp /mnt/config-template/wait_for_columnstore_active /mnt/config-map/wait_for_columnstore_active
# # Wont be needed
if [ "$1" = "zeppelin" ]; 
then
    mkdir -p /zeppelin/notebook
    if [ ! -f "/zeppelin/notebook/notebook.tar" ]; then
        echo "Getting the notebook archive ..."
        curl https://downloads.mariadb.com/sample-data/notebook.tar --output /zeppelin/notebook/notebook.tar
        echo "Extracting bookstore files ..."
        tar -xf /zeppelin/notebook/notebook.tar --directory /zeppelin/notebook
    fi
    find /zeppelin/notebook -type f -name note.json -exec sed -i "s/{{columnstore_host_nm}}/$APPLICATION-$ENVIRONMENT-mcs-sandbox/g" {} +
fi

