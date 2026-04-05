
## Write by SangSoo kim <sskim.luis@gmail.com>
## ex) docker build --rm --build-arg UID=`id -u` --build-arg GID=`id -g` --tag workspace:`date "+%y%m%d"`

# syntax=docker/dockerfile:1.4
FROM ubuntu:20.04
LABEL Luis <sskim.luis@gmail.com>

ARG USER
ENV USER ${USER:-luis}

ARG UID
ENV UID ${UID:-1000}

ARG GID
ENV GID ${GID:-1000}

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Seoul
ENV LANG=ko_KR.UTF-8
ENV LANGUAGE=ko_KR.UTF-8
ENV LC_ALL=ko_KR.UTF-8

## Install basic packages
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    git-core gnupg flex bison build-essential zip curl zlib1g-dev \
    libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc \
    unzip fontconfig

# Install some packages
 RUN apt-get install -y --no-install-recommends \
  -qq sudo bc m4 wget lftp pv tree dosfstools mtools \
    libncurses5-dev libncurses5 libssl-dev liblz4-tool \
    liblzma-dev lzop rsync python3 python3-pip python-is-python3 \
    gcc-multilib g++-multilib libstdc++6 libffi-dev \
    ccache openssh-client locales

## Set locale for Korean
RUN sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN sed -i 's/# ko_KR.UTF-8 UTF-8/ko_KR.UTF-8 UTF-8/' /etc/locale.gen
RUN locale-gen && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone


## Add user for luis
RUN groupadd -g $GID $USER && \
    useradd -m $USER -s /bin/bash -u $UID -g $GID && \
    echo "$USER:sangtn00" | chpasswd && adduser $USER sudo

# Remove cached files
RUN rm -rf /var/lib/apt/lists/* && apt-get autoclean && apt-get autoremove && apt-get clean


WORKDIR /home/$USER
USER $USER
