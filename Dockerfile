FROM debian:buster

LABEL maintainer="fritz@iron.blue" version="1.0" description="Docker container for Shinobi (https://shinobi.video)" 

ENV PUID 1001
ENV PGID 1001

EXPOSE 8080/tcp

CMD ["/bin/bash", "-c", "/home/shinobi/entry.sh"]

HEALTHCHECK CMD ["/bin/bash", "-c", "/home/shinobi/entry.sh health"]

SHELL ["/bin/bash", "-c"]

RUN groupadd -g $PGID shinobi && \
    useradd -m -u $PUID -g shinobi -G users -s /bin/bash shinobi && \
    apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y apt-transport-https lsb-release gnupg util-linux curl && \
    curl -s -o /tmp/nodesource.gpg.key http://deb.nodesource.com/gpgkey/nodesource.gpg.key && \
    apt-key add /tmp/nodesource.gpg.key && \
    echo 'deb http://deb.nodesource.com/node_12.x buster main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src http://deb.nodesource.com/node_12.x buster main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nodejs ffmpeg jq git mariadb-client procps && \
    apt autopurge && \
    apt-get clean && \
    npm i npm -g && \
    rm -rf /var/lib/apt/lists/* && \
    npm cache clean --force

COPY --chown=$PUID:$PGID entry.sh /home/shinobi

# Switch to non-root user and fetch the Shinobi repo, master branch
USER shinobi

RUN cd /home/shinobi && \
    git clone --depth 1 https://gitlab.com/Shinobi-Systems/Shinobi.git --branch master --single-branch Shinobi && \
    cd /home/shinobi/Shinobi && \
    npm install --no-optional --unsafe-perm && \
    npm cache clean --force

WORKDIR /home/shinobi/Shinobi
