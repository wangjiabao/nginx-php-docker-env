# 三节课 PHP 开发环境

## 目录说明
```
─┬─ 工作目录
 │
 ├─ dev-env (本项目)
     ├─ .env ─── 环境变量，定义 工作目录决定路径、主数据库配置、Xdebug 配置等
     │
     ├─ docker-compose.yml ─── docker 模式主文件，定义 nginx, redis, 多版本 php 等服务
     ├─ docker-compose.override.yml ─── 定义 nginx 容器的别名，表示 docker 模式下 内网服务域名。
     ├─ Vagrantfile ─── vagrant 模式主文件，定义 虚拟机中所有的配置，兼容 docker-compose.override.yml 定义的内网服务域名。
     ├─ init_host_list.sh ─── host 文件生成命令
     │
     ├─ nginx ─── nginx 配置文件
     ├─ php ─── php 各版本的配置文件
     │ 
     ├─ logs ─── 日志目录，被挂载到 /data/logs 路径下
     ├─ composer ─── 共享的 COMPOSER_HOME 目录，避免 package 重复下载的问题
     ├─ ... 其他配置
 │
 ├─ 各项目检出的目录名称以 nginx/site-enabled 中声明的路径为准。
 ├─ 新项目普遍以 git repo 的名称检出，有些旧项目以 .gitlab-ci.yml 中定义的 Name 检出
 │
 ├─ service.sanjieke.com
 ├─ admin.sanjieke.com
 │
 ├─ static.sanjieke.cn (旧 cdn 资源文件项目)
 │
 ├─ frontend (前端项目子目录)
     │ 
     ├─ admin.sanjieke.cn.fe
     ├─ banban ─── 有些项目的 Name 和 git repo 的名称不一样
     ├─ cms.admin.sanjieke.cn ─── 另一些项目的 Name 就是 git repo 的名称
     │    │
     │    └─ dist ─── npm i && npm build test 的编译结果，所有前端项目的 nginx root 目录
     ├─ ...
            
```

## 使用说明检出本项目后的操作
1. 检出 *此项目* 至 **工作目录** 下。
2. 将 `export COMPOSER_HOME=/我的工作目录/dev-env/composer` 写入宿主机 `~/.profile` 文件中，使 宿主机 与 虚拟机/容器 共享 composer 缓存。
3. 复制 **.env.example** 为 **.env**。
    - 将 *SJK_WEBROOT* 设置为 上述 **工作目录** 的绝对路径
4. Docker 模式 与 虚拟机模式 二选一。

### 虚拟机模式
1. 安装 [VirtualBox](https://www.virtualbox.org/) 和 [vagrant](https://www.vagrantup.com/)。
2. 在本项目下执行 `vagrant up`
3. 在本项目下执行 `bash init_host_list.sh 192.168.100.10` 并将生成的 served_hosts.txt 内容复制到 *系统 hosts* 中。
    - *192.168.100.10* 为 [Vagrantfile](Vagrantfile#L47) 定义的虚拟机 ip 地址。

### Docker 模式
1. 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)。
    - 国内下载镜像 [for Mac](http://mirrors.aliyun.com/docker-toolbox/mac/docker-for-mac/stable/), [for Windows](http://mirrors.aliyun.com/docker-toolbox/windows/docker-for-windows/stable/)。
2. 将 *.env* 中的 *XDEBUG_REMOTE_HOST* 设置为 **电脑的局域网 IP**，保证 Xdebug 功能可用
3. *选做* 为 Docker Hub 配置 [国内镜像](https://github.com/yeasy/docker_practice/blob/master/install/mirror.md)
4. 在本项目下执行 `docker-compose up` 或 `docker-compose up -d`
    - 如果出现 `pull image` 失败，可以 选择其他镜像或去掉国内镜像。
5. 在本项目下执行 `bash init_host_list.sh 127.0.0.1` 并将生成的 served_hosts.txt 内容复制到 *系统 hosts* 中。

<br>

## 如何添加新项目配置
1. 在 **nginx/site-enabled** 中书写合适的 nginx 配置文件。
2. 如果新项目提供内网调用服务，需要将其内网域名添加到 `docker-compose.override.yml` 中。
3. 执行 `docker-compose build nginx` 以复制新配置到 nginx Image 中。
4. 执行 `docker-composer up -d` 重启服务。

<br>

### 如何分享 docker image 到其他电脑上
```shell script
# 在已有相关 image 的 电脑上执行
docker save dev/php-7{0,1,3} -o dev-env-images-output

# 将文件 dev-env-images-output 传到目标机器上
# 在目标机器上执行
docker load dev-env-images-output
```
