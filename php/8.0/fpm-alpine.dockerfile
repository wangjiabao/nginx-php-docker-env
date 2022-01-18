FROM php:8-fpm-alpine

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk update \
    # alpine 需要安装 tzdata 才能支持时区
    && apk add --no-cache tzdata \
    && apk add --no-cache \
            $PHPIZE_DEPS \
            freetype-dev \
            libjpeg-turbo-dev \
            libpng-dev \
            openldap-dev \
            icu-dev \
            bzip2-dev \
            libxml2-dev \
            libzip-dev \
            ca-certificates \
            curl \
            tar \
            xz \
            openssl

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd ldap intl bz2 zip bcmath pdo_mysql pcntl sockets

RUN pecl install swoole-4.6.4
RUN docker-php-ext-enable swoole

ADD packages/redis-5.3.4.tgz /tmp/build-redis
RUN cd /tmp/build-redis/redis-5.3.4 \
    && phpize \
    && ./configure -q \
    && make \
    && make install \
    && docker-php-ext-enable redis \
    && make clean

RUN docker-php-ext-install -j$(nproc) \
        opcache

COPY packages/composer-1.phar /usr/local/bin/composer

COPY common/fpm/pool.d/* /usr/local/etc/php-fpm.d/

WORKDIR /data/webroot/