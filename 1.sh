#!/bin/bash

# 创建日志文件
LOG_FILE="/var/log/user_setup.log"
touch $LOG_FILE
echo "开始用户数据脚本执行 $(date)" > $LOG_FILE
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
