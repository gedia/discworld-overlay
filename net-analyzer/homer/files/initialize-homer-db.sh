#!/bin/bash

# Variables Used:
# MYSQL_ADMIN_USER     MySQL Administrator user (default: root)
# MYSQL_ADMIN_PASS     MySQL Administrator password
# DB_USER              MySQL user (default: homer)
# DB_PASS              MySQL password (homer_password)
# DB_HOST              MySQL host (default: localhost)
# VHOST_HOSTNAME       The Machine's hostname
# VHOST_ROOT           Root Directory of the VHOST
# MY_SQLSCRIPTSDIR     webapp-config's SQL script directory of the VHOST
# MY_HTDOCSDIR	       The htdocs directory of the VHOST

# Function Definitions
function MYSQL_INITIAL_DATA_LOAD () {
    # Get database user username
    echo "Enter a username for MySQL HOMER user client (empty for homer):"
    read sqlhomeruser
    if [ "$sqlhomeruser" = "" ] ; then
        echo "* Using default (homer)"
        sqlhomeruser="homer"
    fi
    DB_USER="$sqlhomeruser"
    echo "Enter a password for MySQL HOMER user client (empty for random):"
    stty -echo
    read sqlhomerpass
    if [ "$sqlhomerpass" = "" ] ; then
        echo "* Using random"
        sqlhomerpass="$(cat /dev/urandom|tr -dc "a-zA-Z0-9"|fold -w 9|head -n 1)"
    fi
    DB_PASS="$sqlhomerpass"
    stty echo

    echo "---- Beginning initial data load ----"

    echo "Initializing databases..."
    mysql -h "$DB_HOST" -u "$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASS" < "${MY_SQLSCRIPTSDIR}"/mysql/5.0.6_create.sql

    echo "Initializing local DB node..."
    mysql -h "$DB_HOST" -u "$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASS" homer_configuration -e "REPLACE INTO node VALUES(1,'"$DB_HOST"','homer_data','3306','"$DB_USER"','"$DB_PASS"','sip_capture','node1', 1);"

    echo "Setting privileges..."
    mysql -h "$DB_HOST" -u "$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASS" -e "GRANT ALL ON \`homer%\`.* TO '"$DB_USER"'@'%' IDENTIFIED BY '"$DB_PASS"'; FLUSH PRIVILEGES;"
    mysql -h "$DB_HOST" -u "$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASS" -e "GRANT ALL ON \`homer%\`.* TO '"$DB_USER"'@'"$DB_HOST"' IDENTIFIED BY '"$DB_PASS"'; FLUSH PRIVILEGES;"

      echo "---- Homer initial data load complete ----"
}

die() {
        echo "#####"
        echo $1
        echo "#####"
        exit 1
}

if [ $1 = "install" ]; then

    # Get MySQL server hostname
    echo "Enter FQDN where MySQL Server is running (empty for localhost)"
    read mysqlfqdn
    if [ "$mysqlfqdn" = "" ] ; then
        echo "* Using default (localhost)"
        mysqlfqdn="localhost"
        DB_HOST="$mysqlfqdn"
    fi
    # Get MySQL Administrator username
    echo "Enter MySQL Administrator User Name (empty for root):"
    read mysqladminuser
    if [ "$mysqladminuser" = "" ] ; then
        echo "* Using default (root)"
        mysqladminuser="root"
        MYSQL_ADMIN_USER="$mysqladminuser"
    fi
    # Get MySQL Administrator password
    echo "Enter MySQL Administrator User Password:"
    stty -echo
    read mysqladminpass
    MYSQL_ADMIN_PASS="$mysqladminpass"
    stty echo

    # Check if MySQL Service is running
    mysql_started=false
    waited=0
    while [ "$mysql_started" = false ]; do
        mysqladmin -h "$DB_HOST" -u "$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASS" status &> "$VHOST_ROOT"/mysql.status
        if [[ "$(cat "$VHOST_ROOT"/mysql.status)" =~ "Uptime" ]]; then
            echo "** Mysql is now running."
            rm "$VHOST_ROOT"/mysql.status
            mysql_started=true
        else
            echo "* MySQL service is not running. Please start the service for setup to continue. Waited "$waited" seconds so far."
        waited=$(( waited + 2 ))
        sleep 2
        fi
    done
    
    # Check if databases exist: Fetch databases.
    databases=$(mysql -h "$DB_HOST" -u "$MYSQL_ADMIN_USER" -p"$MYSQL_ADMIN_PASS" -s -e 'show databases;')
    
    # Check if databases exist: Look for the homer_data database.
    if [[ ! "$databases" =~ "homer_data" ]]; then
    # If it isn't, import scripts
        MYSQL_INITIAL_DATA_LOAD
    # Otherwise, skip
    else
        echo "Detected Homer databases are already installed. Please provide connection details:"
	    # Get database user username
	echo "Enter the username for configured MySQL HOMER user client (empty for homer):"
	read sqlhomeruser
	if [ "$sqlhomeruser" = "" ] ; then
		echo "* Using default (homer)"
		sqlhomeruser="homer"
	fi
	DB_USER="$sqlhomeruser"
	echo "Enter the password for configured MySQL HOMER user client:"
	stty -echo
	read sqlhomerpass
	DB_PASS="$sqlhomerpass"
	stty echo
    fi

    sed -i s/\{\{\ DB_HOST\ \}\}/"${DB_HOST}"/g "${MY_INSTALLDIR}/api/configuration.php"
    sed -i s/\{\{\ DB_USER\ \}\}/"${DB_USER}"/g "${MY_INSTALLDIR}/api/configuration.php"
    sed -i s/\{\{\ DB_PASS\ \}\}/"${DB_PASS}"/g "${MY_INSTALLDIR}/api/configuration.php"

    # Setup cron jobs
    sed -i s/host=localhost/host="${DB_HOST}"/g "${VHOST_ROOT}/scripts/rotation.ini"
    sed -i s/homer_user/"${DB_USER}"/g "${VHOST_ROOT}/scripts/rotation.ini"
    sed -i s/homer_password/"${DB_PASS}"/g "${VHOST_ROOT}/scripts/rotation.ini"
    (crontab -l ; echo "30 3 * * * ${VHOST_ROOT}/scripts/homer_rotate >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -
    echo "30 3 * * * "${VHOST_ROOT}/scripts/homer_rotate" >> /var/log/cron.log 2>&1" > "${VHOST_ROOT}/scripts/crons.conf"
    crontab "${VHOST_ROOT}/scripts/crons.conf"
    ${VHOST_ROOT}/scripts/homer_rotate

elif [ $1 = "clean" ]; then
        echo $1
fi
