#!/bin/bash
set -e

# ensure current user is root, P4 will check this too, but only on initial server setup. This is for consistency, 
# and to prevent container starting as another user (which can break files)
if [[ $EUID -ne 0 ]]; then
    echo "ERROR : This script (and by extension this container) must be run as root. Exiting ..."
    exit 1
fi

# Server name is always required
if [ -z "$SERVER_NAME" ]; then
    echo ERROR: SERVER_NAME not defined 1>&2
    exit 1;
fi

# Perforce paths
CONFIGURE_SCRIPT=/opt/perforce/sbin/configure-perforce-server.sh
SERVERS_ROOT=/opt/perforce/servers
CONFIG_ROOT=/etc/perforce/p4dctl.conf.d
SERVER_ROOT=$SERVERS_ROOT/$SERVER_NAME

# Default values
P4USER=${P4USER:-p4admin}
P4PORT=${P4PORT:-ssl:1666}

if [ -z "${MODE}" ]; then
    echo "MODE defaulting to normal"
    MODE="normal"
fi

# ensure that mode is normal if server is not set up yet
if [ $MODE != "normal" ]; then

    if [ ! -d $SERVER_ROOT/root ]; then
        echo "Start mode must be normal (or blank) on initial container setup. The container needs to create server files before it can be restarted in another mode."
        exit 1
    fi

    DB_COUNT=$(ls -1q $SERVER_ROOT/root/db.* | wc -l)
    if [ $DB_COUNT -eq 0 ]; then
        echo "ERROR : start mode must be normal (or left blank) on initial container setup. The container needs to create server files before it can be restarted in another mode."
        exit 1
    fi
fi


# The actual perforce server process runs as user perforce, therefore all dirs that Perforce writes to must be owned by user perforce
# Force ownership of logs dir
LOGS_DIR=$SERVERS_ROOT/$SERVER_NAME/logs
if [ -d $LOGS_DIR ]; then
    echo "Claiming ownership of logs dir $LOGS_DIR"
    chown perforce -R $LOGS_DIR 
    chgrp perforce -R $LOGS_DIR
    chmod 700 -R $LOGS_DIR
else
    echo "Logs dir $LOGS_DIR not found, cannot claim"
fi

# force ownership of archives dir
ARCHIVES_DIR=$SERVERS_ROOT/$SERVER_NAME/archives
if [ -d $ARCHIVES_DIR ]; then
    echo "Claiming ownership of archives dir $ARCHIVES_DIR"
    chown perforce -R $ARCHIVES_DIR
    chgrp perforce -R $ARCHIVES_DIR
    chmod 700 -R $ARCHIVES_DIR
else
    echo "Archives dir $ARCHIVES_DIR not found, cannot claim"
fi

# force ownership of journals dir
JOURNALS_DIR=$SERVERS_ROOT/$SERVER_NAME/journals
if [ -d $JOURNALS_DIR ]; then
    echo "Claiming ownership of journals dir $JOURNALS_DIR"
    chown perforce -R $JOURNALS_DIR
    chgrp perforce -R $JOURNALS_DIR
    chmod 700 -R $JOURNALS_DIR
else
    echo "Journals dir $JOURNALS_DIR not found, cannot claim"
fi

# force ownership of database directory
ROOT_DIR=$SERVERS_ROOT/$SERVER_NAME/root
if [ -d $ROOT_DIR ]; then
    echo "Claiming ownership of root dir $ROOT_DIR"
    chown perforce -R $ROOT_DIR
    chgrp perforce -R $ROOT_DIR
    chmod 700 -R $ROOT_DIR
else
    echo "Root dir $ROOT_DIR not found, cannot claim"
fi

# force take ownership of ssl dir, this is needed when passing in from docker mount
if [ -z "${P4SSLDIR}" ]; then
    # assume default location of ssl
    SSL_DIR_TEMP=$SERVERS_ROOT/$SERVER_NAME/root/ssl
    echo "P4SSLDIR not set, assuming default location at $SSL_DIR_TEMP"
else
    SSL_DIR_TEMP=$P4SSLDIR
fi

if [ -d $SSL_DIR_TEMP ]; then
    echo "Claiming ownership of SSL dir $SSL_DIR_TEMP"
    chown perforce -R $SSL_DIR_TEMP
    chmod 700 $SSL_DIR_TEMP

    # use -f and |: to ignore errors if dir empty
    chmod -f 600 -R $SSL_DIR_TEMP/* |:
else
    echo "Declared P4SSLDIR directory $SSL_DIR_TEMP does not exist, cannot claim"
fi

if [ $MODE = "idle" ] ; then
    echo "Container running in idle mode. Perforce has not been started."
    echo "You can manually start Perforce by connecting as root and running p4ctl, or as perforce and running p4d."
    /bin/sh -c "while true ;sleep 5; do continue; done"
else

    # Check if config or root dir exists. If not either, configure it.
    if [ ! -f $CONFIG_ROOT/$SERVER_NAME.conf ] || [ ! -d $SERVER_ROOT/root ]; then
        echo "Perforce server $SERVER_NAME not configured, configuring."

        if [ -z "${P4PASSWD}" ]; then
            echo ERROR: P4PASSWD not defined 1>&2
            exit 1;
        fi

        if [ "$UNICODE" = "true" ]; then
            echo "Unicode mode enabled"
            UNICODE="--unicode"
        else
            echo "Unicode mode disabled"
            UNICODE=""
        fi

        if [ "$CASE_SENSITIVE" = "true" ]; then
            echo "case sensitive mode enabled"
            CASE_SENSITIVE="--case 0"
        else
            echo "case insensitive mode enabled"
            CASE_SENSITIVE="--case 1"
        fi

        # If the root path already exists, we're configuring an existing server
        $CONFIGURE_SCRIPT -n \
            -r $SERVER_ROOT \
            -p $P4PORT \
            -u $P4USER \
            -P $P4PASSWD \
            $UNICODE \
            $CASE_SENSITIVE \
            $SERVER_NAME

        echo "Server info:"
        p4 -p $P4PORT info

        if [ -z "${FORCE_ADMIN_GROUP}" ]; then
            echo "Ignore forced admin group"
        else
            printf "Group: $FORCE_ADMIN_GROUP\n" > /tmp/p4group
            printf "Owners: $P4USER\n" >> /tmp/p4group
    
            if [ "$FORCE_ADMIN_NOEXPIRE" == "true" ]; then
                printf "Timeout: unlimited\n" >> /tmp/p4group
                printf "PasswordTimeout: unlimited\n" >> /tmp/p4group
                echo "Forcing unlimited password and ticket on group $FORCE_ADMIN_GROUP"
            fi

            cat /tmp/p4group | p4 group -i
            rm /tmp/p4group
        fi

        # container exits intentionally at this point, and gets reset, at which point it proceeds to either idle or normal mode

        # copy config to mirror location so available for external use.
        cp -R /etc/perforce /opt/perforce/servers/$SERVER_NAME/config-mirror
    fi

    if [ $MODE = "maintenance" ] ; then

        echo "Starting Perforce server in maintenance mode as user perforce"
        
        cd /opt/perforce/servers/$SERVER_NAME/root
        
        runuser -u perforce -- p4d -p $P4PORT -n

    elif [ $MODE = "normal" ] ; then

        echo "Starting Perforce server in normal mode"
        # Configuring the server also starts it, if we've not just configured a
        # server, we need to start it ourselves.
        p4dctl start $SERVER_NAME

        # Pipe server log and wait until the server dies
        PID_FILE=/var/run/p4d.$SERVER_NAME.pid
        exec /usr/bin/tail --pid=$(cat $PID_FILE) -n 0 -f "$SERVER_ROOT/logs/log"

    fi
fi