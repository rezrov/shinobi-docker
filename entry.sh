#!/bin/bash

cd /home/shinobi/Shinobi

# Generate a password $1 characters long (up to 999)
gen_pw() {
    
    pw_len=$1
    
    [[ $pw_len =~ ^[0-9]{1,3}$ ]] || pw_len=20

    PW=$(< /dev/urandom tr -dc 2-9a-hjkmnp-zA-HJKMNP-Z | head -c $pw_len)
}

# Make sure the database is online and configured for Shinobi
check_db() {
    get_db_params && \
    mysql --host=$DBHOST -u $DBUSER -p$DBUSERPW -e "use ccio;"
}

# TODO
check_procs() {

    for proc_name in cron.js camera.js
    do
        proc_id=`pgrep -f "node.+($proc_name)"`
        if [ "$proc_id" == "" ]; then
            echo "Process $proc_name is not running" 1>&2
            return 1
        fi
        proc_status=`ps -o state --no-headers $proc_id`
        if [[ $proc_status != [DRS] ]]; then
            echo "Process $proc_name is broken (status $proc_status)" 1>&2
            return 1
        fi
    done

    return 0
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

    gen_pw; USERPASS=$PW
    gen_pw; ROOTPASS=$PW

    mysql -u root -pdbpasswd --host db -e "SET PASSWORD FOR 'root'@'%' = PASSWORD('$ROOTPASS');"
    mysql -u root -p$ROOTPASS --host db -e "CREATE USER 'majesticflame'@'%' IDENTIFIED BY '$USERPASS'" 
    mysql -u root -p$ROOTPASS --host db -e "GRANT ALL PRIVILEGES ON ccio.* TO 'majesticflame'@'%'"
    mysql -u root -p$ROOTPASS --host db -e "source sql/framework.sql"

    gen_pw; admin_pw=$PW
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
    gen_pw; cron_key=$PW
    node tools/modifyConfiguration.js addToConfig="{\"cron\":{\"key\":\"$cron_key\"}}" > /dev/null 2>&1

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

# Generate a random password
if [ "$1" == "password" ]; then
    gen_pw $2
    echo $PW
    exit 0;
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
