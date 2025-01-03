FROM ubuntu:18.04

LABEL maintainer="Shukri Adams <contact@shukriadams.com>"

ENV DEBIAN_FRONTEND noninteractive

# Update package list and install wget
RUN apt-get update && apt-get install -y wget gnupg2 && \
    # timezone not present on this distro image
    apt-get install tzdata -y && \
    # Get perforce packages
    wget -q http://package.perforce.com/perforce.pubkey -O - | apt-key add - && \
    echo 'deb http://package.perforce.com/apt/ubuntu bionic release' > /etc/apt/sources.list.d/perforce.sources.list && \

    # install additional requirements
    apt-get install curl -y && \
    apt-get install nano -y && \
    apt-get install python3-minimal -y && \
    apt-get install python3-pip -y && \ 

    # install Perforce packages
    curl https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/helix-p4d-base_2020.1-2298664~bionic_amd64.deb -o /tmp/helix-base.deb && \
    apt-get update && apt install /tmp/helix-base.deb -y && \
    curl https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/helix-p4d_2020.1-2298664~bionic_amd64.deb -o /tmp/helix.deb && \
    apt install /tmp/helix.deb -y && \
    # set permissions
    usermod -aG root perforce && \
    chown -R perforce /opt/perforce && \
    # force p4 trust for all users on container
    echo "p4 trust -yf" >> /etc/profile && \
    
    # clean temporary files
    rm /tmp/helix-base.deb && \
    rm /tmp/helix.deb && \ 
    rm -rf /var/log/* && \
    rm -rf /var/lib/apt/lists/* && \

    # quality-of-life improvements, replace vi with nano, and force trust + login for shell users
    echo "export EDITOR=/bin/nano" >> /etc/bash.bashrc && \
    echo "if [ \"\$FORCE_TRUST_AUTH\" = \"true\" ]; then p4 trust -yf; fi" >> /etc/bash.bashrc && \
    echo "if [ \"\$FORCE_TRUST_AUTH\" = \"true\" ]; then echo \$P4PASSWD | p4 login; fi" >> /etc/bash.bashrc 


# Define volumes for servers and external trigger files
VOLUME /opt/perforce/servers
VOLUME /opt/perforce/triggers

# Note that we do not set default user to something non-root, Perforce requires that we start this container as root.

# Add startup script and run it by default. This contains our custom init logic, and is responsible for starting the Perforce server process
COPY onContainerStart.sh /opt/perforce/onContainerStart.sh
CMD ["/opt/perforce/onContainerStart.sh"]
