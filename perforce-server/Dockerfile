FROM noonien/perforce-base

# Install the perforce server
RUN apt-get update && \
    apt-get install curl -y && \
    apt-get install nano -y && \
    export EDITOR=/bin/nano && \
    curl https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/helix-p4d-base_2019.1-1962178~bionic_amd64.deb -o /tmp/helix-base.deb && \
    apt-get update && apt install /tmp/helix-base.deb -y && \
    curl https://package.perforce.com/apt/ubuntu/pool/release/p/perforce/helix-p4d_2019.1-1962178~bionic_amd64.deb -o /tmp/helix.deb && \
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
