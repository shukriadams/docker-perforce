## Advanced setup

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

    This uses whatever credentials are currently defined in P4USER and P4PASSWD to authenticate with - update these to authenticate with a different user. This obviously has security implications, as any user that has access to your container has access to your admin account.

### Mode

        MODE: idle

    Perforce will automatically exit on most errors, taking the container down with it. This mode disables automatic Perforce starting, but pegs the container to a silent background bash loop. This is useful for troubleshooting, as you can shell into the container and start Perforce manually. 

        MODE: maintenance

    Starts Perforce from daemon, and in debug mode (`p4d -n`). This is also useful for troubleshooting.

    