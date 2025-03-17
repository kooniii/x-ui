#!/bin/bash

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "请以root用户运行此脚本"
    exit 1
fi

# 更新系统并安装必要工具
apt-get update -y
apt-get install -y unzip curl || { echo "工具安装失败"; exit 1; }

# 设置固定的root密码
ROOT_PASSWORD="@Zy123456789"
echo "root:$ROOT_PASSWORD" | chpasswd

# 配置SSH允许root和密码登录
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 创建启动记录
echo "System started at $(date)" > /root/startup.log
echo "Root password: $ROOT_PASSWORD" >> /root/startup.log
chmod 600 /root/startup.log

# 下载并执行额外脚本
curl -L https://raw.githubusercontent.com/nezhahq/scripts/main/agent/install.sh -o agent.sh || { echo "下载失败"; exit 1; }
chmod +x agent.sh
env NZ_SERVER=www.wwcatai.cn:443 NZ_TLS=true NZ_CLIENT_SECRET=Rt9lnHNPmpqam64CWcaCZxF5jXxGJagV ./agent.sh || { echo "执行agent.sh失败"; exit 1; }

# 重启SSH服务，兼容不同系统
if command -v systemctl > /dev/null; then
    systemctl restart ssh || systemctl restart sshd
else
    service ssh restart || service sshd restart
fi

echo "脚本执行完成，root密码为: $ROOT_PASSWORD"
echo "请妥善保存密码并考虑禁用root登录，使用SSH密钥认证更安全"
