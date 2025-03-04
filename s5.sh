#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cd "$(
    cd "$(dirname "$0")" || exit
    pwd
)" || exit

# 颜色设置
Green="\033[32m"
Red="\033[31m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
Font="\033[0m"
source '/etc/os-release'

# OK 和错误信息
OK="${Green}[OK]${Font}"
error="${Red}[错误]${Font}"

check_system() {
    if [[ "${ID}" == "centos" && ${VERSION_ID} -ge 7 ]]; then
        echo -e "${OK} ${Green} 当前系统为 CentOS ${VERSION_ID} ${VERSION} ${Font}"
        INS="yum"
        yum remove firewalld -y
        yum install -y iptables-services
        iptables -F
        iptables -t filter -F
        systemctl enable iptables.service
        service iptables save
        systemctl start iptables.service

    elif [[ "${ID}" == "debian" && ${VERSION_ID} -ge 8 ]]; then
        echo -e "${OK} ${Green} 当前系统为 Debian ${VERSION_ID} ${VERSION} ${Font}"
        apt update
        apt install -y curl wget lsof

    elif [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        echo -e "${OK} ${Green} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        apt update
        apt install -y curl wget lsof
        systemctl disable ufw.service
        systemctl stop ufw.service
    else
        echo -e "${error} ${Red} 当前系统 ${ID} ${VERSION_ID} 不支持，安装中断 ${Font}"
        exit 1
    fi
}

is_root() {
    if [[ $UID -eq 0 ]]; then
        echo -e "${OK} ${Green} 当前用户是 root，进入安装流程 ${Font}"
    else
        echo -e "${error} ${Red} 需要 root 权限，请使用 'sudo -i' 切换到 root 用户后执行 ${Font}"
        exit 1
    fi
}

judge() {
    if [[ $? -eq 0 ]]; then
        echo -e "${OK} ${Green} $1 完成 ${Font}"
    else
        echo -e "${error} ${Red} $1 失败 ${Font}"
        exit 1
    fi
}

install_ss5() {
    # 安装 socks
    if [[ ! -f "/usr/local/bin/socks" ]]; then
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
    # 配置 Socks 服务器
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
            "port": "11886",
            "protocol": "socks",
            "settings": {
                "auth": "password",
                "accounts": [
                    {
                        "user": "vv33",
                        "pass": "vv33"
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
    IP=$(curl -s ipv4.ip.sb)
    echo "============================="
    echo "SOCKS5 代理服务器信息"
    echo "IP 地址: $IP"
    echo "端口号: 11886"
    echo "用户名: vv33"
    echo "密码: vv33"
    echo "============================="
    echo "$IP:11886:vv33:vv33" > /root/ss5.txt
}

s5_install() {
    install_ss5
    config_install
    connect
    systemctl restart sockd.service
    judge "SOCKS5 安装完成"
}

s5_del() {
    systemctl stop sockd.service
    rm -rf /usr/local/bin/socks
    rm -rf /etc/systemd/system/sockd.service
    systemctl daemon-reload
    rm -rf /etc/socks
    judge "删除 SOCKS5"
}

s5_update() {
    config_install
    systemctl restart sockd.service
    connect
    judge "SOCKS5 更新完成"
}

case "$1" in
    install|del|update)
        s5_$1
        ;;
    *)
        echo "使用方法: $0 { install | del | update }"
        exit 1
        ;;
esac
