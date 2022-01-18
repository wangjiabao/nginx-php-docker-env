FROM php:7.3-fpm-alpine

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
        libzip-dev

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd ldap intl bz2 zip xmlrpc bcmath pdo_mysql pcntl sockets

RUN pecl install swoole-4.5.11
RUN docker-php-ext-enable swoole

ADD packages/redis-5.1.1.tgz /tmp/build-redis
RUN cd /tmp/build-redis/redis-5.1.1 \
    && phpize \
    && ./configure -q \
    && make \
    && make install \
    && docker-php-ext-enable redis \
    && make clean

ADD packages/xdebug-2.9.4.tgz /tmp/build-xdebug
RUN cd /tmp/build-xdebug/xdebug-2.9.4 \
    && phpize \
    && ./configure -q \
    && make \
    && make install \
    && docker-php-ext-enable xdebug \
    && make clean

RUN docker-php-ext-install -j$(nproc) \
        opcache

COPY packages/composer-1.phar /usr/local/bin/composer

COPY common/fpm/pool.d/* /usr/local/etc/php-fpm.d/

#php配置
RUN cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

#swoole配置修改
RUN sed -i 'a\swoole.use_shortname=off' /usr/local/etc/php/conf.d/docker-php-ext-swoole.ini

WORKDIR /data/webroot/
