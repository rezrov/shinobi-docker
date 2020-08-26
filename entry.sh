#!/bin/bash

# Make sure the database is online and configured for Shinobi
check_db() {
    mysql --host=mariadb -u root -ppassword -e "use ccio;"
}

# TODO
check_procs() {
    return 0;
}

# Called for health check
if [ "$1" == "health" ]; then
    check_db;
    if [ $? -ne 0 ]; then
        echo "Database connection failed" 1>&2
        exit 1;
    fi
    check_procs;
    if [ $? -ne 0 ]; then
        echo "One or more Shinobi processes have failed" 1>&2
        exit 1;
    fi
    exit 0;
fi

# Called with something unrecognizable
if [ "$1" != "" ]; then
    echo "Unrecognized option." 1>&2
    exit 1;
fi

# Check for first-run
if [ ! -f ~/INITIALIZED ]; then
    mysql -u root -p password --host mariadb -e "CREATE USER 'majesticflame'@'%' IDENTIFIED BY ''" 
    mysql -u root -p password --host mariadb -e "GRANT ALL PRIVILEGES ON ccio.* TO 'majesticflame'@'%'"
    mysql --host=mariadb -u root -ppassword -e "source sql/framework.sql"
    check_db;
    if [ $? -eq 0 ]; then
        touch ~/INITIALIZED;
    else
        echo "Database initialization failed" 1>&2
        exit 1;
    fi
fi

# Called with no parameters, regular startup
node cron.js &
node camera.js
