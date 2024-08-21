# docker-perforce

Container images available @ https://hub.docker.com/r/shukriadams/perforce-server

Peforce in an Ubuntu-based docker container. Based on https://github.com/noonien/docker-perforce-server, now permanently forked. Contains a single Perforce server instance, supporting multiple depots.

This project is split into branches by Perforce servers version. Branch `2020` is for Perforce server 2020.1, `2024` for Perforce 2024.1.

## Volume mapping

This project has an example docker-compose file that assumes the following volume mapping structure for your Perforce server. Your local (files on your container host system) shoud look like

    /
    ├─ core/                    (server core root)
    │  ├─ archives/
    │  │  ├─ spec/
    │  ├─ config-mirror
    │  ├─ journals/
    │  ├─ logs/
    │  ├─ root/                 (server root)
    │  ├─ ssl/  
    ├─ config/                  (config root)
    ├─ depots/                  (depot root)
    │  ├─ depot1/
    │  ├─ depot2/
    ├─ docker-compose.yml

Inside the container, the file structure above corresponds to 

    etc/
    ├─ perforce/                (config root)
    opt/
    ├─ perforce/
    │  ├─ depots/               (depot root)
    │  │  ├─ depot1/
    │  │  ├─ depot2/
    │  ├─ servers/
    │  │  ├─ myserver/          (server core root)
    │  │  │  ├─ archives/
    │  │  │  │  ├─ spec/
    │  │  │  ├─ config-mirror/
    │  │  │  ├─ journals/
    │  │  │  ├─ logs/
    │  │  │  ├─ root/           (server root)
    │  │  │  ├─ ssl/


Spec, journals, logs and ssl are for Perforce's internal use, if you're unfamiliar with them, defaults are suggested, you can change their location later using both Perforce config and Docker volume mapping. Depots is where Perforce stores verion files for a given depot, these can also be broken out stored in different locations (such us on different physical disks/volumes), which is useful for very large projects.

- See the example perforce-server/docker-compose.yml for an example setup. 
- The container will create and set permissions for its core directory automatically.
- You can create directories for your depot(s) in advance. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will not affect container stability, but you will get  write permission errors when you try to submit files to the server under normal Perforce use. It is advisable to do a small test commit every time you setup a depot in a new volume mount, to ensure that write permissions work.

## Permissions

IMPORTANT 

To run the Perforce server, YOU NEED TO SHELL IN AS USER `perforce`. The container doesn't set this as the default user because Perforce setup must done as `root`. This is Perforce quirk. 

## Starting from scratch

TL;DR : Do not volume map `/etc/perforce` the first time you start your container.

This is important for setting up a new server. Perforce autogenerates directories and files in the config root at `/etc/perforce` in the container. Autogeneration happens on container start, and will reoccur every container restart if `/etc/peforce` isn't persisted with a volume mount. The default config that Perforce generates is enough to run a server normally, so you don't have to persist config, but you mostly likely want to.

Perforce's internal config scripts cannot run in an empty directory that is already volume mounted (permission errors etc). So, NEVER VOLUME MAP `/etc/peforce` TO AN EMPTY DIRECTORY. To get config, either create your own config files if you know what they should contain, copy them from an exisiting server, or allow your container to generate config to an unmapped directory. If doing the latter, you will find a copy of config in the mounted directory `core/config-mirror`.  The content of this directory is automatically overwritten each time the container starts, so all changes you make here will be lost. These files are for reference only. Copy them to your local config-root directory, then mount to `/etc/perforce`. You modify your local config-root files as needed.

### Additional config

The username and password in docker-compose will be used to create user the first time you run your container. Changing the compose file afterwards will not update the user - these credentials are never used again. To change the password, use the P4admin tool. All env variables for container config are for setup-time only. Once setup, env vars aren't read anymore. Changes will need to be done via Perforce config.

Available config env variables are:

    SERVER_NAME : <string>
    P4PORT : Should be either "ssl::1666" or "1666", where 1666 is whatever port number you want to expose.
    P4USER : <string>
    P4PASSWD : <string>
    UNICODE : "true|false" (quotes required)
    CASE_SENSITIVE : "true|false" (quotes required)

## Server modes

This container starts Perforce as a regular daemon process using Perforce's own control agent p4dctl. Set the env var START_NODE to `maintenance` to run the Perforce daemon directly in standard maintenance mode, which corresponds to starting the server with `p4d -n`. You can also set START_MODE to `idle`, which starts the container, but not Perforce. Use this mode to debug the container setup and manually start Perforce with your own shell command. This is useful for running Perforce upgrades etc.

To start Perforce manually while in the container run 

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d

To start Perforce in recovery mode use

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d -n

## Depots

Place all depots in /opt/perforce/depots/ in the container, this will cause them to be placed in the corresponding depots volume. Do NOT place them in the core perforce folder, Perforce will let you do this, but the resulting depot will behave strangely, such as writing all files under-the-hood in archive mode.

Note that you will have to manually set filesystem permissions on your depot volume, Perforce will not do this for you.




## Build Container

Requires Docker runtime.

  cd perforce-server
  sh ./build.sh

Note that Perforce public binaries are constantly being updated, you will almost certainly have to udpate the pegged version numbers in the docker file for build to succeed.


