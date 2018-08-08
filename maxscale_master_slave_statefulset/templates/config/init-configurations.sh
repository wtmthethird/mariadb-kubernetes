#!/bin/sh
# the path to the target directory needs to be passed as first argument

set -ex

APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)

for filename in /mnt/config-template/*; do
    sed -e "s/{{APPLICATION}}/$APPLICATION/g" \
	-e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{ADMIN_USER}}/$ADMIN_USER/g" \
        -e "s/{{ADMIN_PASSWORD}}/$ADMIN_PWD/g" \
        -e "s/{{REPLICATION_USER}}/$REPL_USER/g" \
        -e "s/{{REPLICATION_PASSWORD}}/$REPL_PWD/g" \
        $filename > $1/$(basename $filename)
done

if [ "$2" != "" ]; then
   until mysql -h $APPLICATION-$ENVIRONMENT-mdb-ms-$2.$APPLICATION-$ENVIRONMENT-mdb-clust -u $REPL_USER -p$REPL_PWD -e "SELECT 1"
   do
       sleep 5
   done
fi
