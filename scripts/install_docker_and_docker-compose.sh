#!/bin/bash 
# export http_proxy=http://squid.jishu.idc:8000
# export https_proxy=http://squid.jishu.idc:8000
# export no_proxy=*.corp,*.idc,10.*.*.*,172.16.*.*,192.168.*.*,*.local,localhost,127.0.0.1
# export HTTP_PROXY=http://squid.jishu.idc:8000
# export HTTPS_PROXY=http://squid.jishu.idc:8000

set -Eeuo pipefail 

if [ $USER != "root" ]; then
    echo "请使用root用户操作或者sudo"
    exit 1
fi


echo "############安装工具......" && sleep 1
echo "excute time:$(date +"%Y-%m-%d %H:%M:%S")"
#curl  -x http://squid.jishu.idc:8000 -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
curl   -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
# sed -i '13a proxy=http://squid.jishu.idc:8000' /etc/yum.conf
awk ' !x[$0]++{print > "/etc/yum.conf"}' /etc/yum.conf
yum clean all 
echo "step 1: 安装必要的一些系统工具"
yum install -y yum-utils device-mapper-persistent-data lvm2
echo "step 2: 添加软件源信息"
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo


echo "step 3: 判断机器是否需要重新安装docker"

# yum remove -y docker-ce \
# docker-ce-cli \
# docker-ce-client-latest \
# docker-ce-common \
# docker-ce-latest \
# docker-ce-latest-logrotate \
# docker-ce-logrotate \
# docker-ce-engine

echo "step 4: 安装我们需要版本的docker"
yum install docker-ce -y

echo "step 5：创建docker文件目录"
mkdir /cf-data/docker -p

echo "step 6：编辑配置文件"

[[ -d /etc/docker ]]||mkdir /etc/docker
cat << EOF > /etc/docker/daemon.json
{
  "graph": "/cf-data/docker",
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn/"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "20",
    "labels": "",
    "env": ""
  }
}
EOF

# [[ -d /etc/systemd/system/docker.service.d ]]||mkdir /etc/systemd/system/docker.service.d
# cat << EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
# [Service]
# Environment="HTTP_PROXY=squid.jishu.idc:8000" "NO_PROXY=*.corp,*.idc,10.*.*.*,172.16.*.*,192.168.*.*,*.local,localhost,127.0.0.1"
# EOF

# cat << EOF > /etc/systemd/system/docker.service.d/https-proxy.conf
# [Service]
# Environment="HTTPS_PROXY=squid.jishu.idc:8000" "NO_PROXY=*.corp,*.idc,10.*.*.*,172.16.*.*,192.168.*.*,*.local,localhost,127.0.0.1"
# EOF

echo "step 7：冲突的配置"
[[ -f  /etc/sysconfig/docker ]] &&sed -i 's/--log-driver=journald//g' /etc/sysconfig/docker
echo "step 8：重启docker服务"
systemctl enable docker --now
# echo "step 9：登录公司镜像仓库"
# docker login -u ci -p password registry

echo "step 10：安装docker-compose=v2.3.3"
curl -L "https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
#https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-linux-x86_64

if [[  -f /usr/local/bin/docker-compose  ]];then
  chmod +x /usr/local/bin/docker-compose
  docker-compose -v
fi
