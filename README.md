# docker-perforce

Container images available @ https://hub.docker.com/r/shukriadams/perforce-server

Peforce in an Ubuntu-based docker container. Based on https://github.com/noonien/docker-perforce-server, now permanently forked. 

Repo is split into branches for Perforce servers version. Branch `2020` is for Perforce server 2020.1, `2024` for Perforce 2024.1.

## Setup

See the example perforce-server/docker-compose.yml for an example setup. You should create volume mounts directories for your depot(s), but the container will create and permission-set its core directory automatically. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will not affect container stability, but will throw write exceptions when you try to submit files to the server under normal Perforce use. It is advisable to do a small test commit every time you setup a depot in a new volume mount, to ensure that write permissions work.

## Config

This is important for setting up a new server. Perforce autogenerates local database files and some config to `/etc/perforce` in the container. Autogeneration happens on container start, and will reoccur every container restart if `/etc/peforce` isn't persisted with a volume mount. The default config that Perforce generates is enough to run the server, so you don't have to persist this config. 

Perforce cannot generate config in an empty directory that is volume mounted. This is due to the way Perforce's setup script runs. So, NEVER VOLUME MAP `/etc/peforce` TO AN EMPTY DIRECTORY. 

To get config, either create your own config files, copy them from an exisiting server, or allow your container to generate config internally. If doing the latter, you will find a copy of config in the mounted directory `core/config-mirror`. Do not change the content of this directory, it will be overwritten every time the container restarts. Instead, copy to any other suitable location, mount that location as `/etc/perforce`, and then change as necessary.

### Additional config

The username and password in docker-compose will be used to set a first user up. Changing the compose file afterwards will not update the user - the credentials in the compose file are never used again. To change the password, use the P4admin tool. All env variables for container config are for setup-time only. Once setup, env vars aren't read anymore. Changes will need to be done via Perforce config.

Available config env variables are:

    SERVER_NAME : <string>
    P4PORT : Should be either "ssl::1666" or "1666", where 1666 is whatever port number you want to expose.
    P4USER : <string>
    P4PASSWD : <string>
    UNICODE : "true|false" (quotes required)
    CASE_SENSITIVE : "true|false" (quotes required)

## Server modes

This container starts Perforce as a regular daemon process using Perforce's own control agent p4dctl. Set the env var START_NODE to `maintenance` to run the Perforce daemon directly in standard maintenance mode using `p4d -n`. You can also set START_MODE to `idle`, which will star the container in a silent, non-blocking shell loop, but without 
starting Perforce. Use this mode to debug the container itself, or to manually start Perforce with your own shell command. This is useful for running Perforce upgrades etc.

To start Perforce manually while in the container run 

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d

More realistically, you'll want to start the server in recovery mode. Use

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d -n

## Depots

Place all depots in /opt/perforce/depots/ in the container, this will cause them to be placed in the corresponding depots volume. Do NOT place them in the core perforce folder, Perforce will let you do this, but the resulting depot will behave strangely, such as writing all files under-the-hood in archive mode.

Note that you will have to manually set filesystem permissions on your depot volume, Perforce will not do this for you.

## Permissions

To run the Perforce server, you need to shell in as user `perforce`. The container doesn't set this as the default user because Perforce setup must done as `root`. Perforce quirk.


## Build Container

Requires Docker runtime.

  cd perforce-server
  sh ./build.sh

Note that Perforce public binaries are constantly being updated, you will almost certainly have to udpate the pegged version numbers in the docker file for build to succeed.


