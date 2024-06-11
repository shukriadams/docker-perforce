#!/bin/bash

# This script queues an upgrade for Perforce. To use, start container in idle mode, shell in, run this script, exit container, set to
# normal or maintenance mode, and restart it.

set -e

# Perforce paths
CONFIGURE_SCRIPT=/opt/perforce/sbin/configure-perforce-server.sh
SERVERS_ROOT=/opt/perforce/servers
CONFIG_ROOT=/etc/perforce/p4dctl.conf.d

# These vars need to be defined
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

echo "Force running config"

$CONFIGURE_SCRIPT -n \
    -r $SERVER_ROOT \
    -p $P4PORT \
    -u $P4USER \
    -P $P4PASSWD \
    $SERVER_NAME

p4dctl exec -t p4d $SERVER_NAME -- -xu

