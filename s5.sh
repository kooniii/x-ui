#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cd "$(
    cd "$(dirname "$0")" || exit
    pwd
)" || exit

#fonts color
Green="\033[32m"
Red="\033[31m"
# Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
source '/etc/os-release'
#notification information
# Info="${Green}[信息]${Font}"
OK="${Green}[OK]${Font}"
error="${Red}[错误]${Font}"
check_system() {
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
        echo -e "${OK} ${Green} 当前系统为 Centos ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
#	$INS update -y
	yum remove firewalld -y ; yum install -y iptables-services ; iptables -F ; iptables -t filter -F ; systemctl enable iptables.service ; service iptables save ; systemctl start iptables.service

    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]]; then
        echo -e "${OK} ${Green} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font}"
        if which curl > /dev/null; then
            echo "curl is installed"
        else
            app_1="0"
        fi
        if which wget > /dev/null; then
            echo "wget is installed"
        else
            app_2="0"
        fi
        if which lsof > /dev/null; then
            echo "lsof is installed"
        else
            app_3="0"
        fi
        if [ "${app_1}" == "0" ] || [ "${app_2}" == "0" ] || [ "${app_3}" == "0" ]; then
            apt update
        fi
        if [ "${app_1}" == "0" ]; then
            apt install -y curl
        fi
        if [ "${app_2}" == "0" ]; then
            apt install -y wget
        fi
        if [ "${app_3}" == "0" ]; then
            apt install -y lsof
        fi
        ## 添加 apt源
    elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        echo -e "${OK} ${Green} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        if which curl > /dev/null; then
            echo "curl is installed"
        else
            app_1="0"
        fi
        if which wget > /dev/null; then
            echo "wget is installed"
        else
            app_2="0"
        fi
        if which lsof > /dev/null; then
            echo "lsof installed"
        else
            app_3="0"
        fi
        if [ "${app_1}" == "0" ] || [ "${app_2}" == "0" ] || [ "${app_3}" == "0" ]; then
            apt update
        fi
        if [ "${app_1}" == "0" ]; then
            apt install -y curl
        fi
        if [ "${app_2}" == "0" ]; then
            apt install -y wget
        fi
        if [ "${app_3}" == "0" ]; then
            apt install -y lsof
        fi
	systemctl disable ufw.service ; systemctl stop ufw.service
    else
        echo -e "${Error} ${Red} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font}"
        exit 1
    fi
}


is_root() {
    if [ 0 == $UID ]; then
        echo -e "${OK} ${Green} 当前用户是root用户，进入安装流程 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${Red} 当前用户不是root用户，请切换到使用 'sudo -i' 切换到root用户后重新执行脚本 ${Font}"
        exit 1
    fi
}

judge() {
    if [[ 0 -eq $? ]]; then
        echo -e "${OK} ${Green} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${Red} $1 失败${Font}"
        exit 1
    fi
}

sic_optimization() {
    # 最大文件打开数
    sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    echo '* soft nofile 65536' >>/etc/security/limits.conf
    echo '* hard nofile 65536' >>/etc/security/limits.conf

    # 关闭 Selinux
    if [[ "${ID}" == "centos" ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi

}

# 固定端口设置
port_set() {
    port=1080
}

port_exist_check() {
    if [[ 0 -eq $(lsof -i:"${port}" | grep -i -c "listen") ]]; then
        echo -e "${OK} ${Green} 端口未被占用 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${Red} 检测到 ${port} 端口被占用，以下为 ${port} 端口占用信息 ${Font}"
        lsof -i:"${port}"
        echo -e "${OK} ${Green} 5s 后将尝试自动 kill 占用进程 ${Font}"
        sleep 5
        lsof -i:"${port}" | awk '{print $2}' | grep -v "PID" | xargs kill -9
        echo -e "${OK} ${Green} kill 完成 ${Font}"
        sleep 1
    fi
}

# 固定用户名和密码设置
user_set() {
    user="ac25"
    passwd="ac25"
}

install_ss5() {

# Xray Installation
if [ -f "/usr/local/bin/socks" ]; then
    chmod +x /usr/local/bin/socks
else
    wget -O /usr/local/bin/socks --no-check-certificate https://github.com/kissyouhunter/Tools/raw/main/VPS/socks
    chmod +x /usr/local/bin/socks
fi

cat <<EOF > /etc/systemd/system/sockd.service
[Unit]
Description=Socks Service
After=network.target nss-lookup.target

[Service]
User=nobody
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/socks run -config /etc/socks/config.yaml
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sockd.service &> /dev/null
}

config_install() {
#Xray Configuration
mkdir -p /etc/socks
cat <<EOF > /etc/socks/config.yaml
{
    "log": {
        "loglevel": "warning"
    },
    "routing": {
        "domainStrategy": "AsIs"
    },
    "inbounds": [
        {
            "listen": "0.0.0.0",
            "port": "$port",
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "accounts": [
                    {
                        "user": "$user",
                        "pass": "$passwd"
                    }
                ],
                "udp": true
            },
            "streamSettings": {
                "network": "tcp"
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF
systemctl start sockd.service
}

connect() {
	IP=$(curl ipv4.ip.sb)
	echo "IP: $IP"
	echo "端口：$port"
	echo "账户：$user"
	echo "密码：$passwd"
    echo "$IP:$port:$user:$passwd"
	echo "
IP: $IP
端口：$port
账户：$user
密码：$passwd
$IP:$port:$user:$passwd
" >/root/ss5.txt
}

is_root
check_system

s5_install() {
	sic_optimization
	port_set
	port_exist_check
	user_set
	install_ss5
	config_install
	connect
	systemctl restart sockd.service
	judge "安装 ss5 "
}

s5_del() {

	systemctl stop sockd.service
	rm -rf /usr/local/bin/socks
	rm -rf /etc/systemd/system/sockd.service
	systemctl daemon-reload
	rm -rf /etc/socks
	judge "删除 ss5 "
}

s5_update() {
	port_set
    port_exist_check
    user_set
	rm -rf /etc/socks/config.yaml
	config_install
	systemctl restart sockd.service
	connect
}

s5_install
