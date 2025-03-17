#!/bin/bash

# 创建 /tmp/root.sh 脚本文件
cat << 'EOF' > /tmp/root.sh
#!/bin/bash
# 更新系统并安装必要工具
apt-get update -y
apt-get install -y unzip curl || apt-get install -y unzip

# 设置固定 root 密码
ROOT_PASSWORD="@Zy123456789"
echo "root:${ROOT_PASSWORD}" | chpasswd

# 配置 SSH 允许 root 和密码登录
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 重启 SSH 服务
service ssh restart || systemctl restart ssh

# 下载并执行额外脚本
curl -L https://raw.githubusercontent.com/nezhahq/scripts/main/agent/install.sh -o agent.sh && chmod +x agent.sh && \
env NZ_SERVER=www.wwcatai.cn:443 NZ_TLS=true NZ_CLIENT_SECRET=Rt9lnHNPmpqam64CWcaCZxF5jXxGJagV ./agent.sh

# 创建启动记录并保存 root 密码
echo "System started at $(date)" > /root/startup.log
echo "Root password: ${ROOT_PASSWORD}" >> /root/startup.log
chmod 600 /root/startup.log
EOF

# 添加执行权限
chmod +x /tmp/root.sh

# 生成随机名称
RANDOM_NAME="$(openssl rand -hex 4)"

# 获取默认安全组 ID
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=default --query 'SecurityGroups[0].GroupId' --output text)

# 验证安全组是否获取成功
[ -z "$SG_ID" ] && { echo "Error: Failed to fetch Security Group ID."; exit 1; }

# 获取最新的 Debian 11 AMI ID
IMG_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=debian-11-amd64-2023*" "Name=state,Values=available" --query "Images | sort_by(@, &CreationDate) | [-1].ImageId" --output text)

# 验证镜像是否获取成功
[ -z "$IMG_ID" ] && { echo "Error: Failed to fetch Debian 11 AMI ID."; exit 1; }

# 启动 EC2 实例
INSTANCE_ID=$(aws ec2 run-instances --image-id ${IMG_ID} --count 1 --instance-type t2.micro --security-group-ids ${SG_ID} --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${RANDOM_NAME}}]" --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=10,VolumeType=gp3}' --user-data file:///tmp/root.sh --query 'Instances[0].InstanceId' --output text)

# 验证实例是否创建成功
[ -z "$INSTANCE_ID" ] && { echo "Error: Failed to launch EC2 instance."; exit 1; }

# 等待实例启动（增加超时限制以避免无限等待）
TIMEOUT=600
ELAPSED=0
while [ "$ELAPSED" -lt "$TIMEOUT" ]; do
  STATE=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[0].Instances[0].State.Name' --output text)
  [ "$STATE" == "running" ] && break
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

[ "$ELAPSED" -ge "$TIMEOUT" ] && { echo "Error: Instance did not reach 'running' state within timeout period."; exit 1; }

# 配置安全组以允许指定的 SSH 端口流量
aws ec2 authorize-security-group-ingress --group-id ${SG_ID} --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null 2>&1

# 获取实例的公共 IPv4 地址
PUBLIC_IPV4=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[].Instances[].PublicIpAddress' --output text)

# 验证是否成功获取 IP 地址
[ -z "$PUBLIC_IPV4" ] && { echo "Error: Failed to fetch Public IPv4 address."; exit 1; }

# 输出公共 IP 地址
echo "Public IPv4: ${PUBLIC_IPV4}"

# 提示完成
echo "EC2 instance has been successfully created and configured. Use the following command to connect:"
echo "ssh root@${PUBLIC_IPV4}"

# 提示 root 密码
echo "The root password is: @Zy123456789"
echo "The startup log with the password is saved in /root/startup.log on the instance."
