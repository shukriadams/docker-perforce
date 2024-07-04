# docker-perforce

docker-perforce is Peforce server an Ubuntu-based docker container. Container images available @ https://hub.docker.com/r/shukriadams/perforce-server. Based on https://github.com/noonien/docker-perforce-server, now permanently forked.

Releases up to 0.0.4 run on run on Perforce 2020. Releases from 0.0.5 onward run on Perforce 2024.

This container creates a fully-functional Perforce server with 5 client seats. You can apply a license to this server if you wish. This is a production-quality container used at a game studio with 50+ developers, multiple depot and many terabytes of data.

## Build Container

Requires Docker runtime.

  cd perforce-server
  sh ./build.sh

Note that Perforce public binaries are constantly being updated, you will almost certainly have to udpate the pegged version numbers in the docker file for build to succeed.

## Setup

See the example docker-compose.yml for how to quickly scaffold up server. You should create volume mounts directories for your depot(s), but the container will create and permission-set its core directory automatically. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will throw write exceptions when you try to submit files to those depots.

Do not volume mount config (/etc/perforce) when setting up a new container, the container needs to generate config at least once to properly initialize itself. Instead let the start process run, and check container logs to confirm the server initialized. You will find a `config-mirror` directory in the core volume directory. Copy this directory to some place outside this directory (the dir in core is ovewritten each time container starts), and map your safe copy it /etc/perforce. Then restart your container. This is your Perforce internal config, you can change it if you need to.

Note that failure to permanently volume mount config isn't a serious issue - default config will be regenerated each time the container starts, and as long as you don't need custom config and don't mind the extra step of the container generating config and automatically restarting, the server will function normally.

## User

The container itself runs as user `root`, but the actual Perforce server runs as user `perforce`. The root user start Perforce using the `p4dctl`  which in turn runs as the perforce user. This can lead to strange situations with file permissions. Always start this container start as root, and if you alter any files that the server interacts with, from within the container set these to be owned by user perforce. 

## Config

The username and password in docker-compose will be used to set a first user up. Changing the compose file afterwards will not update the user - the credentials in the compose file are never used again. To change the password, use the P4admin tool. All env variables for container config are for setup-time only. Once setup, env vars aren't read anymore. Changes will need to be done via Perforce config.

## Server modes

This container starts Perforce as a regular daemon process using Perforce's own control agent p4dctl. Set the env var START_NODE to `maintenance` to run the Perforce daemon directly in standard maintenance mode using `p4d -n`. You can also set START_MODE to `idle`, which will star the container in a silent, non-blocking shell loop, but without 
starting Perforce. Use this mode to debug the container itself, or to manually start Perforce with your own shell command. This is useful for running Perforce upgrades etc.

To start Perforce manually while in the container run 

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d

More realistically, you'll want to start the server in recovery mode. Use

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d -n

For additional debugging options you can also start the server with

    p4dctl -v 9 start <YOUR SERVER NAME> 

This forces more useful p4dctl messages.

## Depots

Place all depots in /opt/perforce/depots/ in the container, this will cause them to be placed in the corresponding depots volume. Do NOT place them in the core perforce folder, Perforce will let you do this, but the resulting depot will behave strangely, such as writing all files under-the-hood in archive mode.

Note that you will have to manually set filesystem permissions on your depot volume, Perforce will not do this for you.

## SSL

SSL certificates are automatically created by Perforce in the core/root/ssl directory. Because the core directory is always volume mounted, these certifcates will persist and you don't have to do anything special to get SSL to work. The container's start script will always force the correct permissions on this directory.

You can volume map any arbitrary directory with certificates into your container, but the directory should always map to core/root/ssl inside the container, even if you set the P4SSLDIR variable. This seems to be a quirk with Perforce in Docker.