FROM php:7.0-fpm-stretch

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libmcrypt-dev \
        libldap2-dev \
        libicu-dev \
        libbz2-dev \
        libxml2-dev\
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) gd mcrypt ldap intl bz2 zip xmlrpc bcmath pdo_mysql

ADD packages/redis-4.3.0.tgz /tmp/build-redis
RUN cd /tmp/build-redis/redis-4.3.0 \
    && phpize \
    && ./configure -q \
    && make \
    && make install \
    && docker-php-ext-enable redis \
    && make clean

ADD packages/xdebug-2.6.1.tgz /tmp/build-xdebug
RUN cd /tmp/build-xdebug/xdebug-2.6.1 \
    && phpize \
    && ./configure -q \
    && make \
    && make install \
    && docker-php-ext-enable xdebug \
    && make clean

COPY packages/composer-1.phar /usr/local/bin/composer

COPY common/fpm/pool.d/* /usr/local/etc/php-fpm.d/

WORKDIR /data/webroot/
