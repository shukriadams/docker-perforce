FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# Update package list and install wget
RUN apt-get update && apt-get install -y wget gnupg2 && \
    # Get perforce packages
    wget -q http://package.perforce.com/perforce.pubkey -O - | apt-key add - && \
    echo 'deb http://package.perforce.com/apt/ubuntu focal release' > /etc/apt/sources.list.d/perforce.sources.list && \
    # clean up the layer.
    rm -rf /var/log/* \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get install curl -y && \
    apt-get install nano -y && \
    export EDITOR=/bin/nano && \
    apt-get install python3-minimal -y && \
    apt-get install python3-pip -y && \ 
    curl https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/helix-p4d-base_2024.1-2596294~focal_amd64.deb -o /tmp/helix-base.deb && \
    apt-get update && apt install /tmp/helix-base.deb -y && \
    curl https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/helix-p4d_2024.1-2596294~focal_amd64.deb -o /tmp/helix.deb && \
    apt install /tmp/helix.deb -y && \
    # clean temporary files
    rm /tmp/helix-base.deb && \
    rm /tmp/helix.deb && \ 
    rm -rf /var/log/* && \
    rm -rf /var/lib/apt/lists/*

# Volumes for server roots and triggers
VOLUME /opt/perforce/servers
VOLUME /opt/perforce/triggers

# Add startup file and run it by default
COPY run.sh /
CMD ["/run.sh"]
