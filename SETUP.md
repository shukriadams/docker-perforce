# Setup

## Settings

Several server options can be set using environement variables to override default behaviour. Most settings are permanent, that is, they are passed to the Perforce initialization process when you start your container with no existing server state. To change these settings, consult Perforce's documentation.

### Server name

Perforce servers are always named, this name will appear in your license with Perforce, and will also be the name of the directory your server is placed in under '/opt/perforce/servers'. Set

        SERVER_NAME : my-server-name

###  SSL

To create a server with SSL enabled, prefix `ssl::` on your P4PORT value, egs

        P4PORT : ssl::1666

To run without SSL, use

        P4PORT : 1666

### Unicode

    To enable Unicode support for your server, set 

        UNICODE: "true"

    This is used at server initialization only. Default is false.

### Case sensitive

    To enable case sensitivity, set

        CASE_SENSITIVE: "true"

    This is used at server initialization only. Default is false.


### Credentials

    P4USER and P4PASSWD are used to create the default admin user at initialization time. P4USER will continue to be used as the P4USER when shelling into the container. P4PASSWD is not 
    the same as P4PASSWORD, it is not a standard Perforce variable. If however you enable `FORCE_TRUST_AUTH` (see later) P4USER and P4PASSWD will continue to be used to authenticate your
    container shell sessions.

### Force trust and authentication

    Due to the stateless nature of containers, and that Perforce's security is stateful, you will likely find yourself having to enable trust and authenticate each time you access your container after restarting it. You can force automatic trust and authentication with

        FORCE_TRUST_AUTH: "true"

    This uses whatever credentials are currently defined in P4USER and P4PASSWD to authenticate with - update these to authenticate with a different user. This has obvious security implications, as any user that has access to your container has access to your admin account, so use consider and use wisely.

### Force admin group

    By default, your Perforce login will timeout daily and not persist across container restarts. Authentication persistence requires that a user is in a group, and that session timeouts on this group are disabled. You can set this by default on your super user with the following two evironment variables:

        FORCE_ADMIN_GROUP: myAdminGroup
        FORCE_ADMIN_NOEXPIRE: true

    This has obvious security implications, so use consider and use wisely.

### Mode

        MODE: idle

    Perforce will automatically exit on most errors, taking the container down with it. This mode disables automatic Perforce starting, but pegs the container to a silent background bash loop. This is useful for troubleshooting, as you can shell into the container and start Perforce manually. 

        MODE: maintenance

    Starts Perforce from daemon, and in debug mode (`p4d -n`). This is also useful for troubleshooting.

## Restoring from another server

Restoring or transfering a previous Perforce server into a docker container version can normally be roughly outlined as follows.

- Create a fresh container instance with no existing server files. Make sure this server has the same settings (case sensitivity, encoding etc) as your previous server. If you want to change your settings across migration, you'll need to go through Perforce's complex migration process, which is beyond the scope of this guide.
- Copy your source server's relevant checkpoint files to your new servers's core/journal directorys. Perforce may automatically gz checkpoint files, unpack the checkpoint if necessary.
- Shell into your container 
    
        docker exec -it -u perforce YOUR-CONTAINER-NAME bash

- Stop the server process, this should report that the server has been successfully stopped.

        p4dctl stop -a

- Delete the existing Perforce core files that will block a restore

        cd /opt/perforce/servers/YOUR-SERVER-NAME/root
        rm -f db.*
        rm -f *.lbr
        rm -rf server.locks

        cd /opt/perforce/servers/YOUR-SERVER-NAME/journals 
        rm -f journal
        rm -f *.log

        cd /opt/perforce/servers/YOUR-SERVER-NAME/logs 
        rm -f log

- Restore your checkpoint from the root directory

        cd /opt/perforce/servers/YOUR-SERVER-NAME/root 
        p4d -r /opt/perforce/servers/YOUR-SERVER-NAME/root -jr /opt/perforce/servers/YOUR-SERVER-NAME/journals/YOUR-CHECKPOINT-FILE

- Exit your container, and shut it down. 
- Copy your previous server's depots and spec directories into 'depots' and 'core/archives/spec' directories if your new container.
- If you have one, copy your license to the 'core/root' directory. If you don't have a license and restored a server with more than 5 users or 20 workspaces, your server will not start in normal mode. To get your server to start, you will need to start it in debug mode and delete excess users and workspaces - this is also beyond the scope of this guide.
- Restart your container. If everything worked, you should now have a fully restored server - connect to your server or shell in to your container and run `p4 verify -q //...` to confirm that all your content has been properly restored. 

Note though that the above restore is a highly simplified scenario. Often restoring a server will require additional steps based on the complexity of your setup. 

