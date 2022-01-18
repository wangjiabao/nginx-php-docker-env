# 使用 docker 官方提供的 alpine 版 php fpm 做基础镜像
# 编译稍慢
FROM php:7.1-fpm-alpine

# 安装 编译扩展所依赖的 package
# 为了可读性，没有把 所有的 命令 写到一个 RUN 中
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk update \
    # alpine 需要安装 tzdata 才能支持时区
    && apk add --no-cache tzdata \
    && apk add --no-cache \
        # 为所有 编译中软件 标记一个虚拟 package
        --virtual .php-deps \
        # docker 定义的 php 编译组件
        $PHPIZE_DEPS \
        # 以下是各 extension 依赖的 package
        freetype-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libmcrypt-dev \
        openldap-dev \
        icu-dev \
        bzip2-dev \
        libxml2-dev
    # 这些 编译中软件 被后续命令所依赖，不能删除
    # && apk del .php-deps

# php 源码中包含的 extension
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mcrypt \
        ldap \
        intl \
        bz2 \
        zip \
        xmlrpc \
        bcmath \
        pdo_mysql \
        sockets

# 因为 pecl 网络问题，我们将所需版本的 扩展源码加入 git repo, 通过 phpize 和 make 完成编译。
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

ADD packages/imagick-3.4.4.tgz /tmp/build-imagick
RUN apk update \
    && apk add --no-cache \
        imagemagick \
        imagemagick-dev \
    && cd /tmp/build-imagick/imagick-3.4.4 \
    && phpize \
    && ./configure -q \
    && make \
    && make install \
    && docker-php-ext-enable imagick \
    && make clean

RUN docker-php-ext-install -j$(nproc) \
        opcache

# 使用保存在 git repo 的 composer
COPY packages/composer-1.phar /usr/local/bin/composer

# 复制配置文件
COPY common/fpm/pool.d/* /usr/local/etc/php-fpm.d/

# 默认工作目录
WORKDIR /data/webroot/
