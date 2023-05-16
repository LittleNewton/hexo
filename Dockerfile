ARG BASE_IMAGE="debian:latest"

FROM ${BASE_IMAGE}
ARG BASE_IMAGE

MAINTAINER littleNewton <littlenewton6@gmail.com>

# Set the server port as an environmental
ENV HEXO_SERVER_PORT=4000

# Set the git username and email
ENV GIT_USER="LittleNewton"
ENV GIT_EMAIL="littlenewton6@gmail.com>"

# Install utilities. -- Stage 0
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends git curl zsh wget && \
    apt-get clean

# Install docker-ohmyzsh
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.1.5/zsh-in-docker.sh)"

# Install npm and nodejs
RUN curl -sL https://deb.nodesource.com/setup_18.x -o | bash
RUN apt-get -qq update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends nodejs npm && \
    apt-get clean

# Set workdir
WORKDIR /app

# Install hexo itself.
RUN npm install hexo-cli -g
RUN npm install --save hexo-generator-search

# Expose Server Port
EXPOSE ${HEXO_SERVER_PORT}

# Build a base server and configuration if it doesnt exist, then start
CMD \
    if [ "$(ls -A /app)" ]; then \
        echo "***** App directory exists and has content, continuing *****"; \
    else \
        echo "***** App directory is empty, initialising with hexo and hexo-admin *****" && \
        hexo init && \
        npm install && \
        npm install --save hexo-admin; \
    fi; \
    if [ ! -f /app/requirements.txt ]; then \
        echo "***** App directory contains no requirements.txt file, continuing *****"; \
    else \
        echo "***** App directory contains a requirements.txt file, installing npm requirements *****"; \
        cat /app/requirements.txt | xargs npm --prefer-offline install --save; \
    fi; \
    if [ "$(ls -A /app/.ssh 2>/dev/null)" ]; then \
        echo "***** App .ssh directory exists and has content, continuing *****"; \
    else \
        echo "***** App .ssh directory is empty, initialising ssh key and configuring known_hosts for common git repositories (github/gitlab) *****" && \
        rm -rf ~/.ssh/* && \
        ssh-keygen -t rsa -f ~/.ssh/id_rsa -q -P "" && \
        ssh-keyscan github.com > ~/.ssh/known_hosts 2>/dev/null && \
        ssh-keyscan gitlab.com >> ~/.ssh/known_hosts 2>/dev/null && \
        cp -r ~/.ssh /app; \
    fi; \
    echo "***** Running git config, user = ${GIT_USER}, email = ${GIT_EMAIL} *****" && \
    git config --global user.email ${GIT_EMAIL} && \
    git config --global user.name ${GIT_USER} && \
    echo "***** Copying .ssh from App directory and setting permissions *****" && \
    cp -r /app/.ssh ~/ && \
    chmod 600 ~/.ssh/id_rsa && \
    chmod 600 ~/.ssh/id_rsa.pub && \
    chmod 700 ~/.ssh && \
    echo "***** Contents of public ssh key (for deploy) - *****" && \
    cat ~/.ssh/id_rsa.pub && \
    echo "***** Starting server on port ${HEXO_SERVER_PORT} *****" && \
    hexo server -d -p ${HEXO_SERVER_PORT}
