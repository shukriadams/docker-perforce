# docker-perforce

Peforce in a docker container. Based on https://github.com/noonien/docker-perforce-server, now permanently forked. Runs on Perforce 2019, and easy to update to any official Perforce Debian package.

## Details

This collection currently includes:

  - [perforce-base](perforce-base) - Base container, includes the Perforce APT repositories.
  - [perforce-server](perforce-server/) - Perforce Helix Server container.

This creates a fully-functional perforce server with 5 client seats. 

## Setup

See the example docker-compose.yml for how to quickly scaffold up.

You don't need to create a ./data folder, the container will automatically create its own and take it over.

However, you _will_ have to chmod any depot volumes, these are not claimed by the container. Failing to do this will throw write exceptions when you try to submit files to those depots.

NB : When first creating, restart the container once before logging on, this is required for user initialization.

## Initializing 

The username and password in docker-compose will be used to set a first user up. Changing the compose file afterwards will not update the user - the credentials in the compose file are never used again. To change the password, use the P4admin tool.

## Depots

Place all depots in /opt/perforce/depots/ in the container, this will cause them to be placed in the corresponding depots volumes. Do NOT place them in the core perforce folder, Perforce will let you do this, but the resulting depot will behave strangely, such as writing all files under-the-hood in archive mode.
