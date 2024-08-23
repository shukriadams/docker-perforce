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

See the example docker-compose.yml for how to quickly scaffold up a server instance. You should create volume mounts directories for your depot(s), but the container will create and permission-set its core directory automatically. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will throw write exceptions when you try to submit files to those depots.

Do not volume mount config (/etc/perforce) when setting up a new container, the container needs to generate config at least once to properly initialize itself. Instead let the start process run, and check container logs to confirm the server initialized. You will find a `config-mirror` directory in the core volume directory. Copy this directory to some place outside this directory (the dir in core is ovewritten each time container starts), and map your safe copy it /etc/perforce. Then restart your container. This is your Perforce internal config, you can change it if you need to.

Note that failure to permanently volume mount config isn't a serious issue - default config will be regenerated each time the container starts, and as long as you don't need custom config and don't mind the extra step of the container generating config and automatically restarting, the server will function normally.

## User

The container itself runs as user `root`, but the actual Perforce server runs as user `perforce`. The root user starts Perforce using `p4dctl`, which in turn hands control over to the `perforce` user. This can lead to strange situations with file permissions, and it's possible to break your server if a file gets owned by the wrong user. 

In summary, if you intend to run p4d, connect as user perforce. If you intend to run p4ctl, connect as root.

## Config

Most env variabless defined in docker-compose are for setup-time only. For example, username and password are used to set up a super user when the container is run for the first time. Changing these credentials afterwards has no effect (use P4admin app to alter user credentials). These variables are injected into Perforce's own config files that you can find in `etc/perforce` inside the container.

## Server modes

This container starts Perforce as a regular daemon process using Perforce's own control agent p4dctl. Set START_MODE to `idle`, which will start the container in a silent, non-blocking shell loop, but without 
starting Perforce. Use this mode to debug the container itself, or to manually start Perforce with your own shell command. This is useful for diagnosing Perforce issues, upgrading Perforce etc.

WARNING : You have to connect as user 'perforce' if you want to start p4d manually. Use `docker exec -it -u peforce YOURCONTAINERNAME bash` to connect. If you don't specific a user, you will connect as root, and running p4d as root will lead to errors. Once in your container as user perforce, start the server manually with

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d

More realistically, you'll want to start the server in recovery mode. Use

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d -n

To start Perforce in "normal" mode but at maximum verbosity, connect as user root and from any path run

    p4dctl -v 9 start <YOUR SERVER NAME> 

This forces more useful p4dctl messages.

## Depots

All depot files and directories must be owned by user `perforce`, failing to do this will cause submits and p4 verify on those paths to fail. Note that p4 verify fails with a "file missing" error on permission errors.

## SSL

TL;DR : Do not change SSL certificate settings unless you absolutely have to.

SSL certificates are automatically created by Perforce in the core/root/ssl directory. You can place your own cerificates here too. The SSL directory should be owned by perforce with chmod 700, and SSL files should also be owned by user peforce with chmod 600. Having less restrictive permissions will cause Perforce to fail to start with a "certicates too open" error, and having these files owned by another user (like root), or trying to start the server with pd4 when logged in as root, will give an "effective user doesn't own certifcates" error.