# docker-perforce

Container images available @ https://hub.docker.com/r/shukriadams/perforce-server

Peforce in an Ubuntu-based docker container. Based on https://github.com/noonien/docker-perforce-server, now permanently forked. 

Releases up to 0.0.4 run on run on Perforce 2020. Releases from 0.0.5 onward run on Perforce 2024.

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

See the example docker-compose.yml for how to quickly scaffold up server. You should create volume mounts directories for your depot(s), but the container will create and permission-set
its core directory automatically. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will throw write exceptions when you try to submit files to those depots.

## Config

The username and password in docker-compose will be used to set a first user up. Changing the compose file afterwards will not update the user - the credentials in the compose file are never used again. To change the password, use the P4admin tool. All env variables for container config are for setup-time only. Once setup, env vars aren't read anymore. Changes will need to be done via Perforce config.

## Static config

It is recommended, but not required, that you volume mount static config. This will save on unnecessary server reinitializing each time the container starts, and also exposes the config files to you should you want to change config. Copy the core/config-mirror directory to a suitable place on your system, then mount it to `/etc/perforce/` in your container. You can then change the contents of this file. 

IMPORTANT : DO NOT MOUNT THIS DIRECTORY WHEN SETTING UP A NEW CONTAINER. Perforce's internal setup script will fail if it encounters and empty Docker-mounted config directory. Once your container is setup, copy the config directory and mount. DO NOT DIRECTLY MOUNT THE DIRECTORY IN core/config-mirror, this directory is overwritten each time the container starts, and is there only to expose config to you.

## Server modes

This container starts Perforce as a regular daemon process using Perforce's own control agent p4dctl. Set the env var START_NODE to `maintenance` to run the Perforce daemon directly in standard maintenance mode using `p4d -n`. You can also set START_MODE to `idle`, which will star the container in a silent, non-blocking shell loop, but without 
starting Perforce. Use this mode to debug the container itself, or to manually start Perforce with your own shell command. This is useful for running Perforce upgrades etc.

## Depots

Place all depots in /opt/perforce/depots/ in the container, this will cause them to be placed in the corresponding depots volume. Do NOT place them in the core perforce folder, Perforce will let you do this, but the resulting depot will behave strangely, such as writing all files under-the-hood in archive mode.

Note that you will have to manually set filesystem permissions on your depot volume, Perforce will not do this for you.
