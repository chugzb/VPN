#!/bin/bash

# VMess WebSocket 一键安装脚本
# 自定义版本 - 支持多种加密方式和路径配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查root权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}错误: 此脚本需要root权限运行！${NC}"
        exit 1
    fi
}

# 获取服务器IP
get_server_ip() {
    local ip
    ip=$(curl -s -4 https://api.ipify.org 2>/dev/null)
    if [[ -z "$ip" ]]; then
        ip=$(curl -s -6 https://api6.ipify.org 2>/dev/null)
    fi
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I | awk '{print $1}')
    fi
    echo "$ip"
}

# 生成随机字符串
generate_random_string() {
    local length=${1:-8}
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1
}

# 安装依赖
install_dependencies() {
    echo -e "${YELLOW}正在安装依赖包...${NC}"

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y curl wget unzip
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
        yum install -y curl wget unzip epel-release
    else
        echo -e "${RED}不支持的系统类型${NC}"
        exit 1
    fi
}

# 用户输入配置
get_user_config() {
    echo -e "${BLUE}=== VMess WebSocket 配置 ===${NC}"

    # 端口配置
    VMESS_PORT=3000
    echo -e "${YELLOW}端口已固定为 3000${NC}"

    # UUID配置
    read -p "请输入UUID (留空自动生成): " VMESS_UUID
    if [[ -z "$VMESS_UUID" ]]; then
        if command -v uuidgen >/dev/null 2>&1; then
            VMESS_UUID=$(uuidgen)
        else
            VMESS_UUID=$(cat /proc/sys/kernel/random/uuid)
        fi
    fi

    # WebSocket路径配置
    read -p "请输入WebSocket路径 (留空自动生成): " WS_PATH
    if [[ -z "$WS_PATH" ]]; then
        WS_PATH="/$(generate_random_string 8)"
    elif [[ ! "$WS_PATH" =~ ^/ ]]; then
        WS_PATH="/$WS_PATH"
    fi

    # 加密方式选择
    echo -e "${YELLOW}请选择加密方式:${NC}"
    echo "1) auto (自动)"
    echo "2) aes-128-gcm"
    echo "3) chacha20-poly1305"
    echo "4) none"

    while true; do
        read -p "请选择 (1-4, 默认1): " method_choice
        case ${method_choice:-1} in
            1) VMESS_SECURITY="auto"; break ;;
            2) VMESS_SECURITY="aes-128-gcm"; break ;;
            3) VMESS_SECURITY="chacha20-poly1305"; break ;;
            4) VMESS_SECURITY="none"; break ;;
            *) echo -e "${RED}请输入有效选项 (1-4)${NC}" ;;
        esac
    done
}

# 安装V2Ray
install_v2ray() {
    echo -e "${YELLOW}正在安装 V2Ray...${NC}"

    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)

    if [[ ! -f "/usr/local/bin/v2ray" ]]; then
        echo -e "${RED}V2Ray 安装失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}V2Ray 安装完成${NC}"
}

# 生成配置文件
generate_config() {
    echo -e "${YELLOW}正在生成配置文件...${NC}"

    mkdir -p /usr/local/etc/v2ray

    cat > /usr/local/etc/v2ray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": ${VMESS_PORT},
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${VMESS_UUID}",
                        "alterId": 0
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "${WS_PATH}",
                    "headers": {
                        "Host": ""
                    }
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        },
        {
            "protocol": "blackhole",
            "settings": {},
            "tag": "blocked"
        }
    ],
    "routing": {
        "rules": [
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "blocked"
            }
        ]
    }
}
EOF
}

# 启动服务
start_service() {
    echo -e "${YELLOW}正在启动服务...${NC}"

    systemctl daemon-reload
    systemctl enable v2ray
    systemctl restart v2ray

    sleep 2

    if systemctl is-active --quiet v2ray; then
        echo -e "${GREEN}V2Ray 服务启动成功${NC}"
    else
        echo -e "${RED}V2Ray 服务启动失败${NC}"
        systemctl status v2ray
        exit 1
    fi
}

# 配置防火墙
setup_firewall() {
    echo -e "${YELLOW}正在配置防火墙...${NC}"

    if command -v ufw >/dev/null 2>&1; then
        ufw allow ${VMESS_PORT}/tcp
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${VMESS_PORT}/tcp
        firewall-cmd --reload
    fi
}

# 显示配置信息
show_config() {
    local server_ip=$(get_server_ip)

    # 生成VMess链接
    local vmess_config="{\"v\":\"2\",\"ps\":\"VMess-WS\",\"add\":\"${server_ip}\",\"port\":\"${VMESS_PORT}\",\"id\":\"${VMESS_UUID}\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"${WS_PATH}\",\"tls\":\"\"}"
    local vmess_link=$(echo -n "$vmess_config" | base64 -w 0)

    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  VMess WebSocket 安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}服务器地址:${NC} ${server_ip}"
    echo -e "${YELLOW}端口:${NC} ${VMESS_PORT}"
    echo -e "${YELLOW}UUID:${NC} ${VMESS_UUID}"
    echo -e "${YELLOW}额外ID:${NC} 0"
    echo -e "${YELLOW}加密方式:${NC} ${VMESS_SECURITY}"
    echo -e "${YELLOW}传输协议:${NC} ws"
    echo -e "${YELLOW}路径:${NC} ${WS_PATH}"
    echo -e "${YELLOW}TLS:${NC} 关闭"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}VMess链接:${NC}"
    echo -e "${BLUE}vmess://${vmess_link}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}管理命令:${NC}"
    echo -e "启动: ${BLUE}systemctl start v2ray${NC}"
    echo -e "停止: ${BLUE}systemctl stop v2ray${NC}"
    echo -e "重启: ${BLUE}systemctl restart v2ray${NC}"
    echo -e "状态: ${BLUE}systemctl status v2ray${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}注意: 此配置不包含TLS，适合CDN中转使用${NC}"
}

# 主函数
main() {
    clear
    echo -e "${GREEN}VMess WebSocket 一键安装脚本${NC}"
    echo -e "${YELLOW}开始安装...${NC}"

    check_root
    install_dependencies
    get_user_config
    install_v2ray
    generate_config
    start_service
    setup_firewall
    show_config
}

# 运行主函数
main
