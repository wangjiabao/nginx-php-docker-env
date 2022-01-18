# 更改完 host 之后，需要执行以下命令从新构建 nginx 镜像，并重启
docker-compose build nginx
docker-compose up -d