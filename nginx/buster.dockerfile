FROM debian:buster-slim

RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        apt-utils \
        nginx-light \
        libnginx-mod-http-subs-filter \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /etc/nginx/
COPY conf.d/* sites-enabled/* conf.d/
COPY snippets snippets

# 需确保 php-fpm 在 docker compose 中的 service 名称为 php-fpm-7x
RUN sed -i 's#unix:/run/php/php\([0-9]\).\([0-9]\)-fpm.sock#php-fpm-\1\2:9000#g' snippets/*

CMD ["nginx", "-g", "daemon off;"]
