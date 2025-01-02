# docker-perforce

This is a Peforce server in an Ubuntu-based docker container. Container images are available @ https://hub.docker.com/r/shukriadams/perforce-server. This project started as a fork of https://github.com/noonien/docker-perforce-server, but is now indepedently maintained.

This container creates a fully-functional Perforce server with 5 client seats. You can apply a license to this server if you wish. This is a production-quality container used at a game studio with 50+ developers, multiple depots, and many terabytes of data, and multiple container instances.

Branch `2020` is for Perforce 2020, branch `2024` for Perforce 2024. This split is because I maintain two production versions of Perforce on these two versions, and I needed concurrent images for both.

## Volume mapping

This project has an example docker-compose file that assumes the following volume mapping structure for your Perforce server. Your local (files on your container host system) should look like

    /
    ├─ core                     (server core)
    │  ├─ archives
    │  │  └─ spec
    │  ├─ config-mirror
    │  ├─ journals
    │  ├─ logs
    │  └─ root                 
    ├─ config                  (p4dctl config)
    ├─ depots                  (depot root)
    │  ├─ depot1
    │  └─ depot2
    ├─ docker-compose.yml


Inside the container, the file structure above corresponds to 

    etc
    ├─ perforce                (p4dctl config)
    opt
    ├─ perforce
    │  ├─ depots               (depot root)
    │  │  ├─ depot1
    │  │  └─ depot2
    │  ├─ servers
    │  │  ├─ myserver          (server core)
    │  │  │  ├─ archives
    │  │  │  │  └─ spec
    │  │  │  ├─ config-mirror
    │  │  │  ├─ journals
    │  │  │  ├─ logs
    │  │  │  └─ root           

- *p4dctl config root* is where p4dctl reads static config (p4d does not use these files). You can mount your own config here, but it takes a few steps to get the config on a clean server (see later).
- *Depot root* is the default location Perforce expects depots to be placed. 
- *Server core* is a single directory that I use to place all Perforce's important internal directories. This container introduces the "server core" concept so we can mount and persist a single directory containing all Perforce's internal files. This differs from Perforce's own "server root" concept, which is a single directory called "root", containing Perforce's database files, and which is one of several child directories in the server core.

## Volume Directories Setup

See the example docker-compose.yml for how to quickly scaffold up a server instance. 

- The container will create and permission-set the server core directory automatically. 
- Create a `<depot root>` volume mount directoy for your depot(s) and set the permission of this and child directories manually. Depot volumes will require chmod, these are not claimed by the container. Failing to do this will cause p4 verify to fail, as well as throw write exceptions when you try to submit files to those depots.

- Never volume mount an empty directory to `<p4dctl config root>`. Perforce will try to automatically generate files here if none exist exist, and will fail with a permission error when writing to a mounted directory. To mount your custom config, either use files from a previous server instance, or generate new files as follows : After starting your container for the first time with no config mapping, you can find a copy of auto-generated but unused config files in `<server core>/config-mirror`. Copy these files out to a directory on your host, make any desired changes, then volume mount it to `/etc/perforce`.

### Users

There are two users involved in running this container, `root` and `perforce`. The Docker convention is to never run containers as root, but in this case it will impossible to avoid some use of `root`, and while it is possible to avoid root most of the time, you are making your life unnecessarily difficult.

Perforce ships with a built-in setup script that generates config, internal database files etc. This script is called when you launch the container the first time and  it encounters an empty `<server core>` directory. This script must run as root or it will fail, Perforce made it that way, end of story. Once setup has run, you can get away with running your container as user `perforce` most of the time, but from experience, there will still be situations where you can cripple the server with permission errors. Therefore, the custom container start script that this project uses forces you to run as root.

There are normally two ways to start Perforce - eithe with p4dctl, or p4d directly. p4dctl needs to be run as root, it will internally transfer over to the perforce user, while p4d must always be invoked with the perforce user.  If you start `p4d` manually as root, and your server uses SSL, the server will fail with `P4SSLDIR or credentials files not owned by Perforce process effective user.` as SSL certificates are owned by `perforce`.

### On config as Environment variables vs p4ctl config

Env variabless defined in docker-compose are for setup and shelling in to your container, not for regular server running. For example, username and password are used to set up a super user when the container is run for the first time. Changing these credentials afterwards has no effect (use P4admin app to alter user credentials). Setup-time variables are automatically injected into Perforce's own config files in `<p4dctl config root>` when the server is initialized, but this isn't always the case. If you specify a variable and your server fails to start because it's using a different value, you will likely need to add it to p4dctl config. 

### Container modes

Container mode was introduced by this container, it is not a Perforce concept. 

Perforce can be tricky to run properly in a container. Normally it is started with p4ctl, but will exit immediately if you're missing a license, or have file configuration errors. However, the convention is for containers to attach to a single process that keeps the container alive - if Perforce fails to start, your container will exit immediately and you will be unable to get into it to diagnose or fix the issue. To get around this, this project adds the `MODE` environment variable. 

If `MODE` is set to `idle`, your container will start in a silent bash loop and run forever. You can then shell in as `root` and invoke `p4dctl`, or as user `perforce` and invoke `p4d` - the latter is commonly used to start Perforce in recovery or diagnostic mode (see official Perforce documentation for more info). 


If `MODE` is set to `maintenance` the container will start Perforce in maintenance mode for you, using `p4d -n` as user `perforce`. This is handy for automated restores etc.

### On starting Perforce manually

Start your container with MODE=idle. Your container should be running as root - connect to it as user `perforce` (`docker exec -it -u peforce YOURCONTAINERNAME bash`). Once in, start the server manually with

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d

More realistically, you'll want to start the server in recovery mode. Use

    cd /opt/perforce/servers/<YOUR SERVER NAME>/root && p4d -n

You can also start Perforce in "normal" mode, but at maximum verbosity, with

    p4dctl -v 9 start <YOUR SERVER NAME> 

This forces more useful p4dctl messages.

### Depot Permissions

All depot files and directories must be owned by user `perforce`, failing to do this will cause submits and p4 verify on those paths to fail. Note that p4 verify fails with a "file missing" error if it encounters a permission error.

### On SSL

TL;DR : Do not change SSL certificate settings unless you absolutely have to.

SSL certificates are automatically created by Perforce in the core/root/ssl directory. You can place your own cerificates here too. The SSL directory should be owned by perforce with chmod 700, and SSL files should also be owned by user peforce with chmod 600. Having less restrictive permissions will cause Perforce to fail to start with a "certificates too open" error, and having these files owned by another user (like root), or trying to start the server with pd4 when logged in as root, will give an "effective user doesn't own certificates" error.

## Gotchas

### Fixing broken permissions

File permissions seem to be the biggest issue with running Perforce in Docker. In general, all Perforce files should be owned by user `perforce` - check the * Volume Mapping * section above for a list of relevant directories. 

SSL certifactes are more strict, no user other than Perforce should have any access to them, or the directory they are in. `chmod 700 your-ssl-dir`, and `chmod 600 your-ssl-files`.

If your server fails to start, run it in MODE=idle, manually start the server, and check `<server core>/logs/log`, this will usually give you some clue about what is going wrong.

### Restoring a container from checkpoint

Creating a Perforce server from a checkpoint has the following rough structure

- Make sure your intended `<server root>` is completely empty. If you have existing depot or config files, these can be left in place. Start this container on it (in normal mode), it will initialize itself, creating a database for an empty Perforce server. Restart your container to make sure it comes up properly.
- Make sure you map the checkpoint you intend to restore into your container.
- Shell into your container as root, then stop the server process with `p4dctl stop -a`. The container will not exit.
- Manually delete all database files, active server locks, journal, and log (this is covered in the Perforce docs)
- Restore the checkpoint (`cd <server-root> && p4d -r <server-root> -jr <checkpoint file>`)
- Stop the container
- Copy the spec depot files from your original server (<server core>/archives/spec), as well as any other depot files if you haven't already.
- Restart your container - `MODE=maintenance` can be a big help here, as you can run shell commands against Perforce even though the server isn't fully up. Connect as root, then chown all depot files to user `perforce`. Apply your license if necessary, do other housecleaning work. Restart in normal mode if necessary.

## Build locally

Requires Docker runtime.

  cd perforce-server
  sh ./build.sh

Note that Perforce public binaries are constantly being updated, you will almost certainly have to udpate the pegged versions pulled from https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/ in dockerfile for build to succeed. Browse to that URL and find a suitable version update.
