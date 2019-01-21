#!/bin/bash
# Copyright (C) 2018, MariaDB Corporation
#
# This script customizes templates based on the parameters passed to a command-line tool
# the path to the target directory needs to be passed as first argument
function check_true(){
    if [ ! "$1" == "True" ] && [ ! "$1" == "true" ] && [ ! "$1" == "1" ]; then
        echo ""
    else
        echo 1
    fi
}

# APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
# ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"
UM_COUNT={{ .Values.mariadb.columnstore.um.replicas }}
PM_COUNT={{ .Values.mariadb.columnstore.pm.replicas }}
export MARIADB_CS_DEBUG=$(check_true {{ .Values.mariadb.debug }})
RELEASE_NAME={{ .Release.Name }}
#Get last digit of the hostname
MY_HOSTNAME=$(hostname)
SPLIT_HOST=(${MY_HOSTNAME//-/ }); 
CONT_INDEX=${SPLIT_HOST[(${#SPLIT_HOST[@]}-1)]}

MY_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

function expand_templates() {
    sed -e "s/<<MASTER_HOST>>/${MASTER_HOST}/g" \
        -e "s/<<ADMIN_USERNAME>>/${ADMIN_USER}/g" \
        -e "s/<<ADMIN_PASSWORD>>/${ADMIN_PWD}/g" \
        -e "s/<<REPLICATION_USERNAME>>/${REPL_USER}/g" \
        -e "s/<<REPLICATION_PASSWORD>>/${REPL_PWD}/g" \
        -e "s/<<RELEASE_NAME>>/${RELEASE_NAME}/g" \
        -e "s/<<CLUSTER_ID>>/${CLUSTER_ID}/g" \
        -e "s/<<MARIADB_CS_DEBUG>>/${MARIADB_CS_DEBUG}/g" \
        $1
}

if [ ! -z $MARIADB_CS_DEBUG ]; then
    #set +x
    echo '------------------------'
    echo 'Init CS Module Container'
    echo '------------------------'
    echo 'IP:'$MY_IP
    #set -x
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"




if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
    export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
fi

expand_templates /mnt/config-template/start-mariadb-instance.sh >> /mnt/config-map/start-mariadb-instance.sh
# expand_templates /mnt/config-template/liveness.sh >> /mnt/config-map/liveness.sh
# expand_templates /mnt/config-template/readiness.sh >> /mnt/config-map/readiness.sh

if [[ "$CLUSTER_TOPOLOGY" == "columnstore" ]]; then
    if [ ! -z $MARIADB_CS_DEBUG ]; then
        echo "Init Columnstore"
        echo "$MARIADB_CS_NODE:$MARIADB_CS_MASTER"
        echo "Columnstore Init"
        echo "-----------------"
    fi
    if [[ "$MARIADB_CS_NODE" == "UM" && -f "/mnt/config-map/master" ]]; then
        export MARIADB_CS_MASTER="$(cat /mnt/config-map/master)"
    fi



    if [[ "$MARIADB_CS_NODE" == "UM" ]]; then
        if [[ "$CONT_INDEX" -eq 0 ]]; then
            #First PM
            if [ ! -z $MARIADB_CS_DEBUG ]; then
                echo "UM Master"
            fi
            expand_templates /mnt/config-template/init_um_master.sh >> /mnt/config-map/cs_init.sh
            expand_templates /mnt/config-template/init_um_master_pi.sh >> /mnt/config-map/cs_post_init.sh
{{- if .Values.mariadb.columnstore.test}}
            expand_templates /mnt/config-template/test_cs.sh >> /mnt/config-map/test_cs.sh
            expand_templates /mnt/config-template/initdb.sql >> /mnt/config-map/initdb.sql
{{- end }}
{{- if .Values.mariadb.columnstore.sandbox}}
            cp /mnt/config-template/02_load_bookstore_data.sh /docker-entrypoint-initdb.d/02_load_bookstore_data.sh
{{- end }}
            #expand_templates /mnt/config-template/custom.sh >> /docker-entrypoint-initdb.d/custom.sh
        else
            #Any PM but first
            if [ ! -z $MARIADB_CS_DEBUG ]; then
                echo "UM Slave"
            fi
            expand_templates /mnt/config-template/init_um_slave.sh >> /mnt/config-map/cs_init.sh
            expand_templates /mnt/config-template/init_um_slave_pi.sh >> /mnt/config-map/cs_post_init.sh
        fi
    elif [[ "$MARIADB_CS_NODE" == "PM" ]]; then
        #use the last PM to start initialisation
        #if [[ "$CONT_INDEX" -eq $(( PM_COUNT-1 )) ]]; then     
        if [[ "$CONT_INDEX" -eq 0 ]]; then     
            #First PM
            if [ ! -z $MARIADB_CS_DEBUG ]; then
                echo "First PM"
            fi
            expand_templates /mnt/config-template/init_pm_postconf.sh >> /mnt/config-map/cs_init.sh
        else
            #Any PM but first
            if [ ! -z $MARIADB_CS_DEBUG ]; then
                echo "Any other PM"
            fi
            expand_templates /mnt/config-template/init_pm.sh >> /mnt/config-map/cs_init.sh
        fi
    fi
fi