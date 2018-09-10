#!/bin/bash
echo "--------------------------"
echo "start-mariadb-instance.sh"
echo "--------------------------"
set -ex
/bin/sh -x /usr/sbin/runit_bootstrap &

#TODO: Call bookstore_load.sh instead

#TODO: Identify where the data files are 
#TODO: Fix probes
#TODO: Remove debugs
BOOKSTORE_DIR="/usr/local/mariadb/columnstore/mysql/db/bookstore"
BOOKSTORE_LOADED="bookstore.loaded"
BOOKSTORE_CSV="/mnt/bookstore-csv/csv"
if [ ! -f "$BOOKSTORE_DIR/$BOOKSTORE_LOADED"  ]; then
    if [ ! -f "/mnt/bookstore-csv/tar/sandboxdata.tar" ]; then
        echo "Getting the bookstore sandbox archive ..."
        mkdir -p /mnt/bookstore-csv/tar/
        curl https://downloads.mariadb.com/sample-data/books5001.tar --output /mnt/bookstore-csv/tar/sandboxdata.tar
    fi
    if [ ! -d "$BOOKSTORE_CSV" ]; then
        echo "📚 Extracting bookstore files ..."
        mkdir -p $BOOKSTORE_CSV
        tar -xf /mnt/bookstore-csv/tar/sandboxdata.tar --directory $BOOKSTORE_CSV
    fi
else
   echo "📚 Skipping bookstore files ..." 
fi

# Because of MCOL-1624
/bin/sh /mnt/config-map/wait_for_columnstore_active

if [ ! -f "$BOOKSTORE_DIR/$BOOKSTORE_LOADED"  ]; then
    echo "📚 Loading Bookstore Sandbox Data ...."
    # for loop below.
    currentDir=$(pwd)
    cd $BOOKSTORE_CSV
     echo "📚 Creating tables ..."
    sed -i 's/%DB%/bookstore/g'  $BOOKSTORE_CSV/01_load_ax_init.sql
    /usr/local/mariadb/columnstore/mysql/bin/mysql -u root < $BOOKSTORE_CSV/01_load_ax_init.sql
    # 
    echo "📚 Loading bookstore data ..."
    for i in *.mcs.csv.gz; do
        table=$(echo $i | cut -f 1 -d '.')
        zcat  $table.mcs.csv.gz | /usr/local/mariadb/columnstore/bin/cpimport -s ',' -E "'" bookstore $table
        rm -f $table.mcs.csv.gz
    done
    # 
    for i in *.inno.csv.gz; do
        gunzip $i
        table=$(echo $i | cut -f 1 -d '.')
        /usr/local/mariadb/columnstore/mysql/bin/mysql -u root bookstore -e "load data local infile '$table.inno.csv' into table bookstore.$table fields terminated by ',' enclosed by '''';"
        rm -f $table.inno.csv.gz
    done
    # now load the covers table which is innodb so use load data local in file
    cat readme.md
    cd $BOOKSTORE_DIR
    touch "$BOOKSTORE_DIR/bookstore.loaded"
    cd $currentDir
    echo ''
else
    echo "📚 Bookstore Sandbox data exists skiping the load procedure ...."
fi

echo "📚 Enjoy Bookstore Sandbox data."
tailf /dev/null