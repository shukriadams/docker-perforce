# docker-perforce

Container images available @ https://hub.docker.com/r/shukriadams/perforce-server

Peforce in an Ubuntu-based docker container. Based on https://github.com/noonien/docker-perforce-server, now permanently forked. 

Repo is split into branches for Perforce servers version. Branch `2020` is for Perforce server 2020.1, `2024` for Perforce 2024.1.

## Details

This collection currently includes:

  - [perforce-base](perforce-base) - Base container, includes the Perforce APT repositories.
  - [perforce-server](perforce-server/) - Perforce Helix Server container.

This creates a fully-functional perforce server with 5 client seats. 

## Build Container

Requires Docker runtime.

  cd perforce-server
  sh ./build.sh

Note that Perforce public binaries are constantly being updated, you will almost certainly have to udpate the pegged version numbers in the docker file for build to succeed.

## Setup

See the example docker-compose.yml for how to quickly scaffold up server. You should create volume mounts directories for your depot(s), but the container will create and permission-set its core directory automatically. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will throw write exceptions when you try to submit files to those depots.

Do not volume mount /etc/perforce on start, this will cause an internal setup script failure. Let the start process start, check
container logs to confirm the server initialized. You will find `config-mirror` directory in the directory you mounted to `/opt/perforce/servers/myserver/`. Copy this directory to some place outside this directory, and map it to /etc/perforce, then restart your container. This is your Perforce internal config. You don't have to change anything in it, but should you wish to, this is where to add them.

Note that failure to mount config after creation isn't a serious issue - default config will be regenerated each time the container is started, and as long as you don't need custom config and don't mind the extra step of the container generating config and automatically restarting, the server will function normally this way.

Binding /etc/perforce to a volume right from the start does not work because of issues in Perforce's internal setup scripts that fail to run when they encounter an empty directory in a volume mount. 


## Config

The username and password in docker-compose will be used to set a first user up. Changing the compose file afterwards will not update the user - the credentials in the compose file are never used again. To change the password, use the P4admin tool. All env variables for container config are for setup-time only. Once setup, env vars aren't read anymore. Changes will need to be done via Perforce config.

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
