#!/bin/bash

# Variables Used:
# ALLOWED_HOSTS	       FQDN for the netbox server
# DB_HOST              PostgreSQL host (default: localhost)
# DB_PORT	       PostgreSQL port (default: empty)
# DB_NAME	       Database name (default: netbox)
# DB_ADMIN_USER        PostgreSQL Administrator username (default: postgres)
# DB_ADMIN_PASS        PostgreSQL Administrator password
# DB_USER              PostgreSQL username (default: netbox)
# DB_PASS              PostgreSQL password
# DB_ADMIN_USER_ENC    PostgreSQL Administrator username, URL Encoded (default: postgres)
# DB_ADMIN_PASS_ENC    PostgreSQL Administrator password, URL Encoded
# DB_USER_ENC          PostgreSQL username, URL Encoded (default: netbox)
# DB_PASS_ENC          PostgreSQL password, URL Encoded
# SECRET_KEY	       Key used for secure generation of random numbers and strings
# VHOST_ROOT           Root Directory of the VHOST
# MY_SQLSCRIPTSDIR     webapp-config's SQL script directory of the VHOST
# MY_HTDOCSDIR	       The htdocs directory of the VHOST
# LOAD_SAMPLE	       Load initial sample data

# Function Definitions
function urlencode() {
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}

function PostgreSQL_INITIAL_DATA_LOAD () {
    # Get database user username
    echo "Enter a username for PostgreSQL user client (empty for netbox):"
    read sqlnetboxuser
    if [ "$sqlnetboxuser" = "" ] ; then
        echo "* Using default (netbox)"
        sqlnetboxuser="netbox"
    fi
    DB_USER="$sqlnetboxuser"
    DB_USER_ENC=$(urlencode "${DB_USER}")
    echo "Enter a password for PostgreSQL user client (empty for random):"
    stty -echo
    read sqlnetboxpass
    if [ "$sqlnetboxpass" = "" ] ; then
        echo "* Using random"
        sqlnetboxpass="$(cat /dev/urandom|tr -dc "a-zA-Z0-9"|fold -w 9|head -n 1)"
    fi
    DB_PASS="$sqlnetboxpass"
    DB_PASS_ENC=$(urlencode "${DB_PASS}")
    stty echo

    echo "---- Creating Database ----"

    /usr/bin/psql -c "CREATE DATABASE ${DB_NAME};" postgresql://"${DB_ADMIN_USER_ENC}":"${DB_ADMIN_PASS_ENC}"@"${DB_HOST}":"${DB_PORT}"
    /usr/bin/psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" postgresql://"${DB_ADMIN_USER_ENC}":"${DB_ADMIN_PASS_ENC}"@"${DB_HOST}":"${DB_PORT}"
    /usr/bin/psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" postgresql://"${DB_ADMIN_USER_ENC}":"${DB_ADMIN_PASS_ENC}"@"${DB_HOST}":"${DB_PORT}"

    echo "---- Database Created ----"
}

die() {
        echo "#####"
        echo $1
        echo "#####"
        exit 1
}

if [ $1 = "install" ]; then

    # Get PostgreSQL server hostname
    echo "Enter FQDN where PostgreSQL Server is running (empty for localhost)"
    read PostgreSQLfqdn
    if [ "$PostgreSQLfqdn" = "" ] ; then
        echo "* Using default (localhost)"
        PostgreSQLfqdn="localhost"
        DB_HOST="$PostgreSQLfqdn"
    fi
    # Get PostgreSQL server port
    echo "Enter port number to which PostgreSQL Server is listening (empty for default)"
    read PostgreSQLport
    if [ "$PostgreSQLport" = "" ] ; then
        echo "* Using default (5432)"
        PostgreSQLport="5432"
        DB_PORT="$PostgreSQLport"
    fi
    # Get PostgreSQL Administrator username
    echo "Enter PostgreSQL Administrator User Name (empty for postgres):"
    read PostgreSQLadminuser
    if [ "$PostgreSQLadminuser" = "" ] ; then
        echo "* Using default (postgres)"
        PostgreSQLadminuser="postgres"
        DB_ADMIN_USER="$PostgreSQLadminuser"
        DB_ADMIN_USER_ENC=$(urlencode "${DB_ADMIN_USER}")
    fi
    # Get PostgreSQL Administrator password
    echo "Enter PostgreSQL Administrator User Password:"
    stty -echo
    read PostgreSQLadminpass
    DB_ADMIN_PASS="$PostgreSQLadminpass"
    DB_ADMIN_PASS_ENC=$(urlencode "${DB_ADMIN_PASS}")
    stty echo

    # Get netbox database name
    echo "Enter database name for use by netbox (empty for netbox)"
    read PostgreSQLdbname
    if [ "$PostgreSQLdbname" = "" ] ; then
        echo "* Using default (netbox)"
        PostgreSQLdbname="netbox"
        DB_NAME="$PostgreSQLdbname"
    fi

    # Check if PostgreSQL Service is running
    PostgreSQL_started=false
    waited=0
    while [ "$PostgreSQL_started" = false ]; do
        /usr/bin/psql -c "SELECT now() - pg_postmaster_start_time();" postgresql://"${DB_ADMIN_USER_ENC}":"${DB_ADMIN_PASS_ENC}"@"${DB_HOST}":"${DB_PORT}" &> "$VHOST_ROOT"/PostgreSQL.status
        if [[ "$(cat "$VHOST_ROOT"/PostgreSQL.status)" =~ "?column?" ]]; then
            echo "** PostgreSQL is now running."
            rm "$VHOST_ROOT"/PostgreSQL.status
            PostgreSQL_started=true
        else
            echo "* PostgreSQL service is not running. Please start the service for setup to continue. Waited "$waited" seconds so far."
        waited=$(( waited + 2 ))
        sleep 2
        fi
    done

    # Check if databases exist: Fetch databases.
    databases=$(/usr/bin/psql -c "SELECT datname FROM pg_database;" postgresql://"${DB_ADMIN_USER_ENC}":"${DB_ADMIN_PASS_ENC}"@"${DB_HOST}":"${DB_PORT}")

    # Check if databases exist: Look for the netbox database.
    if [[ ! "$databases" =~ "netbox" ]]; then

    # If it isn't, import scripts
        PostgreSQL_INITIAL_DATA_LOAD

	# Edit netbox configuration
	sed -i s/\{\{\ DB_NAME\ \}\}/"${DB_NAME}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_HOST\ \}\}/"${DB_HOST}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_PORT\ \}\}/"${DB_PORT}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_USER\ \}\}/"${DB_USER}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_PASS\ \}\}/"${DB_PASS}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ ALLOWED_HOSTS\ \}\}/"${VHOST_HOSTNAME}"/g "${MY_INSTALLDIR}/netbox/configuration.py"

	KEY=$(/usr/bin/python2 ${MY_INSTALLDIR}/generate_secret_key.py)

	sed -i s/\{\{\ APP_KEY\ \}\}/"${KEY}"/g "${MY_INSTALLDIR}/netbox/configuration.py"

	# Set timezone
	sed -ie "s/UTC/$(sed 's:/:\\/:g' /etc/timezone)/g" "${MY_INSTALLDIR}/netbox/configuration.py"

	# Install Database Schema
	cd "${MY_INSTALLDIR}" && "./manage.py" migrate

	# Create Super User
	cd "${MY_INSTALLDIR}" && "./manage.py" createsuperuser

	# Collect Static Files
	cd "${MY_INSTALLDIR}" && "./manage.py" collectstatic

	# Load Initial Data
	read -p "Would you like to load initial sample data? (y/n)?" LOAD_SAMPLE
	case "$LOAD_SAMPLE" in
	    y|Y ) echo "* Loading Initial Sample Data";cd "${MY_INSTALLDIR}" && "./manage.py" loaddata initial_data;;
	    n|N ) echo "* Skipping loading of Sample Data";;
	    * ) echo "Please enter y or n";;
	esac


    # Otherwise, skip
    else
        echo "Detected netbox databases are already installed. Please provide connection details:"

	# Get database user username
	echo "Enter the username for configured PostgreSQL netbox user client (empty for netbox):"

	read sqlnetboxuser
	if [ "$sqlnetboxuser" = "" ] ; then
		echo "* Using default (netbox)"
		sqlnetboxuser="netbox"
	fi

	DB_USER="$sqlnetboxuser"
	DB_USER_ENC=$(urlencode "${DB_USER}")

	echo "Enter the password for configured PostgreSQL netbox user client:"
	stty -echo
	read sqlnetboxpass
	DB_PASS="$sqlnetboxpass"
	DB_PASS_ENC=$(urlencode "${DB_PASS}")
	stty echo

	# Edit netbox configuration
	sed -i s/\{\{\ DB_NAME\ \}\}/"${DB_NAME}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_HOST\ \}\}/"${DB_HOST}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_PORT\ \}\}/"${DB_PORT}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_USER\ \}\}/"${DB_USER}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ DB_PASS\ \}\}/"${DB_PASS}"/g "${MY_INSTALLDIR}/netbox/configuration.py"
	sed -i s/\{\{\ ALLOWED_HOSTS\ \}\}/"${VHOST_HOSTNAME}"/g "${MY_INSTALLDIR}/netbox/configuration.py"

	# Set timezone
	sed -ie "s/UTC/$(sed 's:/:\\/:g' /etc/timezone)/g" "${MY_INSTALLDIR}/netbox/configuration.py"

	# Install Database Schema
	cd "${MY_INSTALLDIR}" && "./manage.py" migrate

	# Collect Static Files
	cd "${MY_INSTALLDIR}" && "./manage.py" collectstatic --noinput
    fi

elif [ $1 = "clean" ]; then
        echo $1
fi
