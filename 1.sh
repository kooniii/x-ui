#!/bin/bash

# 创建日志文件
LOG_FILE="/var/log/user_setup.log"
touch $LOG_FILE
echo "开始用户数据脚本执行 $(date)" > $LOG_FILE

# 设置root密码 - 请替换YOUR_PASSWORD为实际密码
PASSWORD="Wndy58123456@."
echo root:$PASSWORD | sudo chpasswd root
if [ $? -eq 0 ]; then 
    echo "更改root密码成功" >> $LOG_FILE
else 
    echo "更改root密码失败" >> $LOG_FILE
fi

# 修改SSH配置，允许root登录和密码认证
sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
if [ $? -eq 0 ]; then 
    echo "启用PermitRootLogin成功" >> $LOG_FILE
else 
    echo "启用PermitRootLogin失败" >> $LOG_FILE
fi

sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
if [ $? -eq 0 ]; then 
    echo "启用PasswordAuthentication成功" >> $LOG_FILE
else 
    echo "启用PasswordAuthentication失败" >> $LOG_FILE
fi

# 重新加载SSH服务
sudo systemctl reload sshd
if [ $? -eq 0 ]; then 
    echo "重新加载sshd配置成功" >> $LOG_FILE
else 
    echo "重新加载sshd配置失败" >> $LOG_FILE
fi

# 安装基本工具
sudo apt update
sudo apt install -y curl wget gnupg gpg systemd
if [ $? -eq 0 ]; then 
    echo "安装基本工具成功" >> $LOG_FILE
else 
    echo "安装基本工具失败" >> $LOG_FILE
fi

# 运行vps.sh脚本
wget -qO- git.io/vps.sh | bash
if [ $? -eq 0 ]; then 
    echo "运行vps.sh脚本成功" >> $LOG_FILE
else 
    echo "运行vps.sh脚本失败" >> $LOG_FILE
fi

# 运行SK5.sh脚本
curl -s https://gist.githubusercontent.com/daxigua12/5307d93984750b47d4a59bfffd104574/raw/c41ed8717012b8672e51b69a596f1d6f0e6e3073/SK5.sh | sudo bash
if [ $? -eq 0 ]; then 
    echo "运行SK5.sh脚本成功" >> $LOG_FILE
else 
    echo "运行SK5.sh脚本失败" >> $LOG_FILE
fi

# 安装ZeroTier
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import
if [ $? -eq 0 ]; then 
    echo "导入ZeroTier gpg密钥成功" >> $LOG_FILE
else 
    echo "导入ZeroTier gpg密钥失败" >> $LOG_FILE
fi

z=$(curl -s 'https://install.zerotier.com/' | gpg)
if [ $? -eq 0 ]; then 
    echo "$z" | sudo bash
    echo "安装ZeroTier成功" >> $LOG_FILE
else 
    echo "安装ZeroTier失败" >> $LOG_FILE
fi

# 下载并执行 x-ui 安装脚本
wget --no-check-certificate https://raw.githubusercontent.com/kooniii/x-ui/refs/heads/main/install_auto.sh -O install_auto.sh
if [ $? -eq 0 ]; then 
    echo "下载 x-ui 安装脚本成功" >> $LOG_FILE
else 
    echo "下载 x-ui 安装脚本失败" >> $LOG_FILE
fi

bash install_auto.sh
if [ $? -eq 0 ]; then 
    echo "执行 x-ui 安装脚本成功" >> $LOG_FILE
else 
    echo "执行 x-ui 安装脚本失败" >> $LOG_FILE
fi

# 创建目标目录并下载 x-ui.db
TARGET_DIR="/etc/x-ui"
sudo mkdir -p $TARGET_DIR
if [ $? -eq 0 ]; then 
    echo "创建目录 $TARGET_DIR 成功" >> $LOG_FILE
else 
    echo "创建目录 $TARGET_DIR 失败" >> $LOG_FILE
fi

wget --no-check-certificate https://raw.githubusercontent.com/kooniii/x-ui/main/x-ui.db -O $TARGET_DIR/x-ui.db
if [ $? -eq 0 ]; then 
    echo "下载 x-ui.db 到 $TARGET_DIR 成功" >> $LOG_FILE
else 
    echo "下载 x-ui.db 到 $TARGET_DIR 失败" >> $LOG_FILE
fi

# 重启 x-ui 服务
sudo systemctl restart x-ui
if [ $? -eq 0 ]; then 
    echo "重启 x-ui 服务成功" >> $LOG_FILE
else 
    echo "重启 x-ui 服务失败" >> $LOG_FILE
fi

echo "脚本执行完成 $(date)" >> $LOG_FILE
