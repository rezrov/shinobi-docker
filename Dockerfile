FROM debian:buster

LABEL maintainer="fritz@iron.blue" version="1.0" description="Docker container for Shinobi (https://shinobi.video)" 

ENV PUID 1001
ENV PGID 1001

EXPOSE 8080/tcp

CMD ["/bin/bash", "-c", "/home/shinobi/entry.sh"]

HEALTHCHECK CMD ["/bin/bash", "-c", "/home/shinobi/entry.sh health"]

SHELL ["/bin/bash", "-c"]

USER root
WORKDIR /root

# Get node.js from the source
COPY nodesource.gpg.key /root/

RUN groupadd -g $PGID shinobi && \
    useradd -m -u $PUID -g shinobi -G users -s /bin/bash shinobi && \
    apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y apt-transport-https lsb-release gnupg util-linux curl && \
    apt-key add nodesource.gpg.key && \
    echo 'deb https://deb.nodesource.com/node_12.x buster main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_12.x buster main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nodejs jq build-essential git ffmpeg mariadb-client procps && \
    npm i npm -g && \
    rm -rf /var/lib/apt/lists/* && \
    npm cache clean --force

# Switch to non-root user and fetch the Shinobi repo, master branch
USER shinobi

COPY entry.sh /home/shinobi

RUN cd /home/shinobi && \
    git clone --depth 1 https://gitlab.com/Shinobi-Systems/Shinobi.git --branch master --single-branch Shinobi && \
    cd /home/shinobi/Shinobi && \
    npm install --unsafe-perm && \
    npm cache clean --force

WORKDIR /home/shinobi/Shinobi
