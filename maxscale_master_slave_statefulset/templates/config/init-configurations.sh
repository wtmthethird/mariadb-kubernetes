#!/bin/sh
# the path to the target directory needs to be passed as first argument

set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

APPLICATION=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 1)
ENVIRONMENT=$(hostname -f | cut -d '.' -f 2 | cut -d '-' -f 2)
ADMIN_USER=$(cat /mnt/secrets/admin-username)
ADMIN_PWD=$(cat /mnt/secrets/admin-password)
REPL_USER=$(cat /mnt/secrets/repl-username)
REPL_PWD=$(cat /mnt/secrets/repl-password)
DB_HOST="$(hostname -f | cut -d '.' -f 1).$(hostname -f | cut -d '.' -f 2)"

if [ "$2" == "maxscale" ]; then
    # ensure we replace with a configurations that will fail
    MASTER_HOST="should-not-be-used-here"
else
    # if this is not a maxscale instance, make sure to ask maxscale who is the master
    MASTER_HOST=$(perl "$DIR"/register-instance-pkg.pl $DB_HOST http $APPLICATION-$ENVIRONMENT-mdb-mxs-0.$APPLICATION-$ENVIRONMENT-mdb-clust 8989 admin mariadb)
fi

for filename in /mnt/config-template/*; do
    sed -e "s/{{MASTER_HOST}}/$MASTER_HOST/g" \
        -e "s/{{APPLICATION}}/$APPLICATION/g" \
	-e "s/{{ENVIRONMENT}}/$ENVIRONMENT/g" \
        -e "s/{{ADMIN_USER}}/$ADMIN_USER/g" \
        -e "s/{{ADMIN_PASSWORD}}/$ADMIN_PWD/g" \
        -e "s/{{REPLICATION_USER}}/$REPL_USER/g" \
        -e "s/{{REPLICATION_PASSWORD}}/$REPL_PWD/g" \
        $filename > $1/$(basename $filename)
done
