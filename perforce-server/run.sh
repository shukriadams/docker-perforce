#!/bin/bash
set -e

# Perforce paths
CONFIGURE_SCRIPT=/opt/perforce/sbin/configure-perforce-server.sh
SERVERS_ROOT=/opt/perforce/servers
CONFIG_ROOT=/etc/perforce/p4dctl.conf.d


# These need to be defined
if [ -z "$SERVER_NAME" ]; then
    echo FATAL: SERVER_NAME not defined 1>&2
    exit 1;
fi
if [ -z "$P4PASSWD" ]; then
    echo FATAL: P4PASSWD not defined 1>&2
    exit 1;
fi

# Default values
P4USER=${P4USER:-p4admin}
P4PORT=${P4PORT:-ssl:1666}

SERVER_ROOT=$SERVERS_ROOT/$SERVER_NAME

if [ -z "$START_MODE" ]; then
    echo "START_MODE defaulting to normal"
    START_MODE="normal"
fi


if [ $START_MODE = "idle" ] ; then
    echo "Container running in idle mode. Perforce has not been started."
    /bin/sh -c "while true ;sleep 5; do continue; done"
else

    # Check if the server was configured. If not, configure it.
    if [ ! -f $CONFIG_ROOT/$SERVER_NAME.conf ]; then
        echo Perforce server $SERVER_NAME not configured, configuring.

        if [ "$UNICODE" = "true" ]; then
            echo "Unicode mode enable"
            UNICODE="--unicode"
        else
            echo "Unicode mode disable"
            UNICODE=""
        fi

        if [ "$CASE_SENSITIVE" = "true" ]; then
            echo "case sensitive mode enable"
            CASE_SENSITIVE="--case 0"
        else
            echo "case insensitive mode enable"
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

        echo Server info:
        p4 -p $P4PORT info
        # container exits intentionally at this point, and gets reset, at which point it proceeds to either maintenance or normal mode

        # copy config to mirror location so available for external use
        cp -R /etc/perforce /opt/perforce/servers/$SERVER_NAME/config-mirror
    fi

    if [ $START_MODE = "maintenance" ] ; then
        echo "Starting Perforce daemon in maintenance mode"
        cd /opt/perforce/servers/$SERVER_NAME/root && p4d -n
    else
        # Configuring the server also starts it, if we've not just configured a
        # server, we need to start it ourselves.
        p4dctl start $SERVER_NAME
        # Pipe server log and wait until the server dies
        PID_FILE=/var/run/p4d.$SERVER_NAME.pid
        exec /usr/bin/tail --pid=$(cat $PID_FILE) -n 0 -f "$SERVER_ROOT/logs/log"
    fi
fi