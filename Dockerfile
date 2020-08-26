FROM debian:buster

LABEL maintainer="fritz@iron.blue" version="1.0" description="Docker container for Shinobi (https://shinobi.video)" 

ENV USERNAME shinobi
ENV PUID 1001
ENV PGID 1001
ENV DBHOST mariadb
ENV DBUSER root
ENV DBPASS dbpasswd

EXPOSE 8080/tcp

CMD ["/bin/bash"]

#TODO
HEALTHCHECK CMD ["/bin/bash", "-c", "entry.sh health"]

SHELL ["/bin/bash", "-c"]

USER root
WORKDIR /root

# Get node.js from the source
COPY nodesource.gpg.key /root/

# TODO: Remove before publishing
RUN echo 'Acquire::HTTP::Proxy "http://172.17.0.1:33142";' >> /etc/apt/apt.conf.d/01proxy && \
    echo 'Acquire::HTTPS::Proxy "false";' >> /etc/apt/apt.conf.d/01proxy && \
    groupadd -g $PGID $USERNAME && \
    useradd -m -u $PUID -g $USERNAME -G users -s /bin/bash $USERNAME && \
    apt-get update && \
    apt-get install -y apt-utils && \
    apt-get install -y apt-transport-https lsb-release gnupg util-linux curl && \
    apt-key add nodesource.gpg.key && \
    echo 'deb https://deb.nodesource.com/node_12.x buster main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_12.x buster main' >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y nodejs uuid-runtime build-essential git ffmpeg mariadb-client && \
    npm i npm -g && \
    rm -rf /var/lib/apt/lists/* && \
    npm cache clean --force

# Switch to non-root user and fetch the Shinobi repo, master branch
USER $USERNAME
RUN cd /home/$USERNAME && \
    git clone --depth 1 https://gitlab.com/Shinobi-Systems/Shinobi.git --branch master --single-branch Shinobi && \
    cd /home/$USERNAME/Shinobi && \
    npm install --unsafe-perm && \
    npm audit fix --force && \
    cp conf.sample.json conf.json && \
    node tools/modifyConfiguration.js addToConfig="{\"db\":{\"host\":\"$DBHOST\"}}" \
    node tools/modifyConfiguration.js addToConfig="{\"db\":{\"key\":\"$DBPASS\"}}" \
    node tools/modifyConfiguration.js addToConfig="{\"cron\":{\"key\":\"$(uuidgen)\"}}" \     
    cp super.sample.json super.json && \
    touch INSTALL/installed.txt && \
    npm cache clean --force

WORKDIR /home/$USERNAME
