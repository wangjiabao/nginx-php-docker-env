FROM nginx:stable-alpine

WORKDIR /etc/nginx/
COPY conf.d/* sites-enabled/* conf.d/
COPY snippets snippets

# 注释不支持的 三方 mod 配置
# docker 模式的前端项目需配合 浏览器 pac 设置方可使用
RUN sed -i 's|^subs_filter|#subs_filter|g' snippets/pre-proxy.conf

# 需确保 php-fpm 在 docker compose 中的 service 名称为 php-fpm-7x
RUN sed -i 's#unix:/run/php/php7.\([0-9]\)-fpm.sock#php-fpm-7\1:9000#g' snippets/*
