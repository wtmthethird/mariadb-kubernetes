#!/bin/bash
RELEASE_NAME={{ .Release.Name }}
DATABASE_SERVICE="${RELEASE_NAME}-mdb-cs-um-module"
mkdir -p /zeppelin/notebook
if [ ! -f "/zeppelin/notebook/notebook.tar" ]; then
    echo "Getting the notebook archive ..."
    curl https://downloads.mariadb.com/sample-data/notebook.tar --output /zeppelin/notebook/notebook.tar
    echo "Extracting notebook files ..."
    tar -xf /zeppelin/notebook/notebook.tar --directory /zeppelin/notebook
fi
if [[ "$CLUSTER_TOPOLOGY" == "galera" ]]; then
find /zeppelin/notebook -type f -name note.json -exec sed -i "s/{columnstore_host_nm}/$DATABASE_SERVICE/g" {} +
