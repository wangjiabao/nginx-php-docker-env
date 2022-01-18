# 快速登录到 nginx 容器里
container_id=`docker ps -q -f name=devenv_nginx`
docker exec -it $container_id sh
