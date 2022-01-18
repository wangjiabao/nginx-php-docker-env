# debian stretch 包含的 php 版本恰好为 7.0, 直接使用它的 package 可以节省编译很多时间与空间。
# 只是其 php-redis 版本为 3.x, 这与其他环境不同，但并不破坏兼容性。
FROM debian:stretch-slim

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        ca-certificates \
    && apt-get install --no-install-recommends -y \
        php-fpm \
        php-sqlite3 \
        php-mbstring \
        php-ldap \
        php-mysql \
        php-xml \
        php-curl \
        php-gd \
        php-intl \
        php-bz2 \
        php-zip \
        php-xmlrpc \
        php-bcmath \
        php-igbinary \
        php-redis \
        php-xdebug \
        php-opcache \
    && rm -rf /var/lib/apt/lists/*

COPY packages/composer-1.phar /usr/local/bin/composer

COPY common/fpm/pool.d/* docker/php-fpm.d/* /etc/php/7.0/fpm/pool.d/

EXPOSE 9000

WORKDIR /data/webroot/

CMD [ "php-fpm7.0", "--nodaemonize" ]
