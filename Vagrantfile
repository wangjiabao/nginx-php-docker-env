# -*- mode: ruby -*-
# vi: set ft=ruby :

# 从 docker-compose.override.yml 文件中读取 host 数组
require 'yaml'
hosts_config = YAML.load_file('docker-compose.override.yml')
hosts_list = hosts_config['services']['nginx']['networks']['default']['aliases']

# 官方文档 https://docs.vagrantup.com
Vagrant.configure("2") do |config|

  # 使用国内镜像的 box 文件
  # https://www.vagrantup.com/docs/vagrantfile/machine_settings.html#config-vm-box_url
  config.vm.box = "ubuntu/bionic64"
  config.vm.box_check_update = false
  config.vm.box_url = [
    "https://mirrors.ustc.edu.cn/ubuntu-cloud-images/bionic/current/bionic-server-cloudimg-amd64-vagrant.box",
    "https://mirrors.huaweicloud.com/ubuntu-cloud-images/bionic/current/bionic-server-cloudimg-amd64-vagrant.box",
    "https://mirrors.cloud.tencent.com/ubuntu-cloud-images/bionic/current/bionic-server-cloudimg-amd64-vagrant.box",
    "https://mirrors-i.tuna.tsinghua.edu.cn/ubuntu-cloud-images/bionic/current/bionic-server-cloudimg-amd64-vagrant.box"
  ]

  # ubuntu 的 aliyun 镜像
  config.vm.provision "shell", inline: <<-SHELL
    sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
    sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
    timedatectl set-timezone Asia/Shanghai
  SHELL

  config.vm.provider "virtualbox" do |vb|
    # 支持 vagrant in WSL 管理 Windows Host 的虚拟机
    # https://www.vagrantup.com/docs/other/wsl.html
    # https://github.com/hashicorp/vagrant/issues/8604#issuecomment-303259512
    vb.customize [ "modifyvm", :id, "--uartmode1", "disconnected" ]

    # 虚拟机内存限制，默认为 2GB。修改后需重启虚拟机
    vb.memory = 2048
  end

  # web 虚拟机
  config.vm.define "default", primary: true do |web|
    # 端口转发默认开启
    # https://www.vagrantup.com/docs/networking/forwarded_ports.html
    web.vm.network "forwarded_port", guest: 80, host: 8058

    # 与旧 VM 使用一样的 IP 地址，不用改 host。新旧 VM 不能同时启动
    web.vm.network "private_network", ip: "192.168.100.10"

    web.vm.synced_folder ".", "/vagrant"

    # 将本地项目路径挂载到服务器的 /data/webroot 上
    # 使用 dev-env 的上层目录作为工作目录
    # 使用 www-data 作为整个工作目录的用户。
    # 假如执行 php cli 或 composer 时遇到 文件权限 的问题，可以通过 sudo -u www-data 来执行
    web.vm.synced_folder "..", "/data/webroot", :owner => 'www-data', :group => 'www-data'
    web.vm.synced_folder "system", "/data/webroot/system", :owner => 'www-data', :group => 'www-data'
    web.vm.synced_folder "logs", "/data/logs", :owner => 'www-data', :group => 'www-data'
    web.vm.synced_folder "composer", "/data/composer", :owner => 'www-data', :group => 'www-data'

    # 再次执行这些命令的方法
    # 1. vm 启动状态 执行 vagrant provision
    # 2. vm 关闭状态 执行 vagrant up --provision
    web.vm.provision "web-packages", type: "shell", inline: <<-SHELL
      # php 仓库

      rm /etc/apt/sources.list.d/ondrej-ubuntu-php-bionic.list
      add-apt-repository -ysn ppa:ondrej/php
      # 使用 https://lug.ustc.edu.cn/wiki/mirrors/help/revproxy 提供的反向代理
      #sed -i 's#http://ppa.launchpad.net#http://launchpad.proxy.ustclug.org#g' /etc/apt/sources.list.d/ondrej-ubuntu-php-bionic.list

      # 创建日志文件夹
      # 虽然 /data/logs 目录会通过 共享目录的方式挂载进来，但挂载前会导致 nginx 启动失败。这样就过于依赖其他配置了
      # 还是先创建一个日志目录比较好
      mkdir -p /data/logs/{app,nginx,php,supervisor} && chown www-data:www-data /data/logs

      apt-get update
      apt-get install -y zip redis-server nginx-light libnginx-mod-http-subs-filter

      # php 运行环境
      apt-get install -y php{7.0,7.1,7.3}-{cli,fpm,sqlite3,mbstring,ldap,mysql,xml,curl,gd,intl,bz2,zip,xmlrpc,bcmath}
      apt-get install -y php-{igbinary,xdebug,imagick}
      apt-get install -y php{7.0,7.1}-mcrypt

      apt-get clean
      phpenmod xdebug
    SHELL

    web.vm.provision "php-redis", type: "shell", inline: <<-SHELL
      # php 7.0/7.1 使用缓存下来的的 php-redis 4.3 版本
      dpkg -i /vagrant/php/packages/php-redis_4.3.0-1+ubuntu18.04.1+deb.sury.org+1_amd64.deb

      # 安装 php7.3 编译环境
      apt-get update
      apt-get install -y php7.3-dev
      apt-get clean

      # 为 php7.3 编译 php-redis 5
      tar xf /vagrant/php/packages/redis-5.1.1.tgz -C /tmp/
      cd /tmp/redis-5.1.1
      phpize7.3
      ./configure -q
      make
      make install
    SHELL

    # php 配置项
    web.vm.provision "php-config", type: "shell", inline: <<-SHELL
        for i in `ls /etc/php/`; do
          rsync -r /vagrant/php/common/* /etc/php/$i/;
        done
        service php7.0-fpm restart
        service php7.1-fpm restart
        service php7.3-fpm restart
    SHELL

    # VM 的 hosts 更新
    web.vm.provision "self-host", type: "shell", run: "always", args: hosts_list , inline: <<-SHELL
      # 删除已有数据并重新加入标记
      sed -i '/HOST_SIGN/,$d' /etc/hosts
      echo '# HOST_SIGN for service' >> /etc/hosts

      # 加入 redis 域名
      echo '127.0.0.1 redis.local' >> /etc/hosts

      # 加入 业务域名
      for domain in "$@"; do
        echo "127.0.0.1 ${domain}" >> /etc/hosts
      done

      echo "sjk host injected"
    SHELL

    # 下载 composer.phar
    web.vm.provision "composer", type: "shell", inline: <<-SHELL
      # 将 composer 加入 git repo 
      cp /vagrant/php/packages/composer-1.phar /usr/bin/composer
      chmod +x /usr/bin/composer

      # 所有用户使用同一 composer home 配置
      echo 'export COMPOSER_HOME=/data/composer' > /etc/profile.d/composer-home.sh

      # 将用户 vagrant 加到 www-data 用户组中，减少权限问题
      usermod -aG www-data vagrant
    SHELL

    # 每次启动都会执行的命令
    web.vm.provision "web-config", type: "shell", run: "always", inline: <<-SHELL
      # nginx 和 php 的一些配置文件
      # 放在 host 系统，每次启动都重新复制，然后重启服务
      rsync -r /vagrant/nginx/* /etc/nginx/
      service nginx restart

      # 从 .env 文件中获得数据库配置文件
      echo '; 此文件所有的改动都将在虚拟机重启后被重置' > /vagrant/system/system.ini
      export $(grep -v '^#' /vagrant/.env | xargs -d '\n') \
        && cat /vagrant/system/system-${SJK_DATABASE}.ini >> /vagrant/system/system.ini

      echo "vm started"
    SHELL

  end

end
