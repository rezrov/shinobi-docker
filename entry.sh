#!/bin/bash

cd /home/shinobi/Shinobi

# Make sure the database is online and configured for Shinobi
check_db() {
    get_db_params && \
    mysql --host=$DBHOST -u $DBUSER -p$DBUSERPW -e "use ccio;"
}

# TODO
check_procs() {
    node_count=`ps --no-heading -C node | wc -l`
    if [ $node_count -eq 2 ]; then
        return 0;
    fi
    return 1;    
}

get_db_params() {
    DBHOST=`jq -r '.db .host' < conf.json`
    DBROOTPW=`jq -r '.db .key' < conf.json`
    DBUSER=`jq -r '.db .user' < conf.json`
    DBUSERPW=`jq -r '.db .password' < conf.json`

    if [ "$DBHOST" == "" -o "$DBROOTPW" == "" -o "$DBUSER" == "" -o "DBUSERPW" == "" ]; then
        return 1
    fi
}

# Called for health check
if [ "$1" == "health" ]; then
    
    check_db
    
    if [ $? -ne 0 ]; then
        echo "Database connection failed" 1>&2
        exit 1
    fi
    
    check_procs;
    
    if [ $? -ne 0 ]; then
        echo "One or more Shinobi processes have failed" 1>&2
        exit 1
    fi
    
    exit 0
    
fi

# Check for first-run
if [ "$1" == "initialize" ]; then

    USERPASS=`uuidgen`
    ROOTPASS=`uuidgen`

    mysql -u root -pdbpasswd --host db -e "SET PASSWORD FOR 'root'@'%' = PASSWORD('$ROOTPASS');"
    mysql -u root -p$ROOTPASS --host db -e "CREATE USER 'majesticflame'@'%' IDENTIFIED BY '$USERPASS'" 
    mysql -u root -p$ROOTPASS --host db -e "GRANT ALL PRIVILEGES ON ccio.* TO 'majesticflame'@'%'"
    mysql -u root -p$ROOTPASS --host db -e "source sql/framework.sql"

    admin_pw=`uuidgen`
    cat <<EOF > super.json
[
  {
    "mail":"admin@shinobi.video",
    "pass":"$admin_pw"
  }
]
EOF
    cp conf.sample.json conf.json
    node tools/modifyConfiguration.js addToConfig="{\"db\":{\"host\":\"db\"}}" > /dev/null 2>&1
    node tools/modifyConfiguration.js addToConfig="{\"db\":{\"key\":\"$ROOTPASS\"}}" > /dev/null 2>&1
    node tools/modifyConfiguration.js addToConfig="{\"db\":{\"password\":\"$USERPASS\"}}" > /dev/null 2>&1
    node tools/modifyConfiguration.js addToConfig="{\"cron\":{\"key\":\"$(uuidgen)\"}}" > /dev/null 2>&1

    check_db;
    
    if [ $? -eq 0 ]; then
        touch ~/INITIALIZED;
        echo "Initilization complete." 1>&2
        echo "Admin username: admin@shinobi.video" 1>&2
        echo "Admin password: $admin_pw" 1>&2
        echo "Browse to http://localhost:8080/super to get started" 1>&2
        echo "Docs: https://shinobi.video/docs/start#content-configuration" 1>&2
        exit 0;
    else
        echo "Initialization failed" 1>&2
        exit 1;
    fi
    
fi

# Called with something unrecognizable
if [ "$1" != "" ]; then
    echo "Unrecognized option." 1>&2
    exit 1;
fi

# Called with no parameters, regular startup
echo -n "Checking configuration" 1>&2

while [ ! -f /home/shinobi/INITIALIZED ]; do
    sleep 5
    echo -n "." 1>&2
done

echo " Starting." 1>&2

node ./cron.js &
node ./camera.js
