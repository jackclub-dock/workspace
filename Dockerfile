FROM codercom/code-server

FROM ubuntu:bionic
MAINTAINER jack "958691165@qq.com"

USER root

#时区设置
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' >/etc/timezone

ADD sources.list /etc/apt/
ARG ROOT_PASSWORD=mj123456

RUN apt update \
    && apt install -yqq sudo vim less libltdl7 git \
    && apt install -yqq php php-xml php-json php-mysql \
        php-mbstring php-xdebug composer php-redis unzip \
        php-zip php-tokenizer php-intl php-curl php-gd php-bcmath \
        php-dev \
    && composer global require slince/composer-registry-manager \
    && composer repo:use aliyun \
    && apt install -yqq mysql-client \
    && apt install -yqq openssh-server \
    && echo "${ROOT_PASSWORD}\n${ROOT_PASSWORD}\n" | passwd root \
    && apt install -yqq openssl net-tools locales \
    && locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ADD ./config/sshd_config /etc/ssh/

ENV TERM=xterm

RUN apt install -yqq curl \
    && curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
    && apt install -yqq redis-tools

ENV NVM_DIR /root/.nvm
RUN \[ -s "$NVM_DIR/nvm.sh" \] && \. $NVM_DIR/nvm\.sh && \
    nvm install v10.15.1 && \
    npm i -g cnpm && \
    npm i -g yarn

WORKDIR /root
RUN git clone https://github.com/swoole/swoole-src.git && \
       cd swoole-src && \
       git checkout v4.3.3 && \
       phpize && \
       ./configure --enable-openssl --enable-sockets && \
       make && make install

RUN echo "[swoole]\nextension = swoole.so" > /etc/php/7.2/cli/conf.d/swoole.ini \
    && wget https://phar.phpunit.de/phpunit-7.0.phar && \
    chmod +x phpunit-7.0.phar && \
    mv phpunit-7.0.phar /usr/local/bin/phpunit

RUN mkdir -p /run/sshd

COPY --from=0 /usr/local/bin/code-server /usr/local/bin/code-server
RUN chmod +x /usr/local/bin/code-server

RUN echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf

RUN mkdir -p /home/code-server

RUN curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

COPY config/passwd /etc/passwd

CMD /usr/sbin/sshd -f /etc/ssh/sshd_config -D
