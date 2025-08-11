#!/bin/bash

# VLESS Reality 一键安装脚本
# 自定义版本 - 支持多种伪装网站和优化配置

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 预设的伪装网站列表
DEST_SITES=(
    "www.microsoft.com"
    "www.apple.com"
    "www.google.com"
    "www.amazon.com"
    "www.cloudflare.com"
    "www.github.com"
)

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
    echo -e "${BLUE}=== VLESS Reality 配置 ===${NC}"

    # 端口配置
    while true; do
        read -p "请输入端口号 (1-65535, 默认443): " REALITY_PORT
        if [[ -z "$REALITY_PORT" ]]; then
            REALITY_PORT=443
            break
        elif [[ "$REALITY_PORT" =~ ^[0-9]+$ ]] && [ "$REALITY_PORT" -ge 1 ] && [ "$REALITY_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}请输入有效的端口号 (1-65535)${NC}"
        fi
    done

    # UUID配置
    read -p "请输入UUID (留空自动生成): " REALITY_UUID
    if [[ -z "$REALITY_UUID" ]]; then
        if command -v uuidgen >/dev/null 2>&1; then
            REALITY_UUID=$(uuidgen)
        else
            REALITY_UUID=$(cat /proc/sys/kernel/random/uuid)
        fi
    fi

    # 伪装网站选择
    echo -e "${YELLOW}请选择伪装网站:${NC}"
    for i in "${!DEST_SITES[@]}"; do
        echo "$((i+1))) ${DEST_SITES[$i]}"
    done
    echo "$((${#DEST_SITES[@]}+1))) 自定义"

    while true; do
        read -p "请选择 (1-$((${#DEST_SITES[@]}+1)), 默认1): " site_choice
        site_choice=${site_choice:-1}

        if [[ "$site_choice" =~ ^[0-9]+$ ]] && [ "$site_choice" -ge 1 ] && [ "$site_choice" -le $((${#DEST_SITES[@]}+1)) ]; then
            if [ "$site_choice" -eq $((${#DEST_SITES[@]}+1)) ]; then
                read -p "请输入自定义域名: " DEST_SITE
                if [[ -z "$DEST_SITE" ]]; then
                    echo -e "${RED}域名不能为空${NC}"
                    continue
                fi
            else
                DEST_SITE="${DEST_SITES[$((site_choice-1))]}"
            fi
            break
        else
            echo -e "${RED}请输入有效选项${NC}"
        fi
    done

    # Short ID配置
    read -p "请输入Short ID (留空自动生成): " SHORT_ID
    if [[ -z "$SHORT_ID" ]]; then
        SHORT_ID=$(openssl rand -hex 4)
    fi
}

# 安装Xray
install_xray() {
    echo -e "${YELLOW}正在安装 Xray-core...${NC}"

    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta

    if [[ ! -f "/usr/local/bin/xray" ]]; then
        echo -e "${RED}Xray 安装失败${NC}"
        exit 1
    fi

    echo -e "${GREEN}Xray 安装完成${NC}"
}

# 生成密钥对
generate_keys() {
    echo -e "${YELLOW}正在生成密钥对...${NC}"

    local key_output=$(/usr/local/bin/xray x25519)
    PRIVATE_KEY=$(echo "$key_output" | head -1 | awk '{print $3}')
    PUBLIC_KEY=$(echo "$key_output" | tail -1 | awk '{print $3}')

    if [[ -z "$PRIVATE_KEY" ]] || [[ -z "$PUBLIC_KEY" ]]; then
        echo -e "${RED}密钥生成失败${NC}"
        exit 1
    fi
}

# 生成配置文件
generate_config() {
    echo -e "${YELLOW}正在生成配置文件...${NC}"

    mkdir -p /usr/local/etc/xray

    cat > /usr/local/etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": ${REALITY_PORT},
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${REALITY_UUID}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "${DEST_SITE}:443",
                    "xver": 0,
                    "serverNames": [
                        "${DEST_SITE}"
                    ],
                    "privateKey": "${PRIVATE_KEY}",
                    "shortIds": [
                        "${SHORT_ID}"
                    ]
                }
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
            "tag": "blocked"
        }
    ]
}
EOF
}

# 启动服务
start_service() {
    echo -e "${YELLOW}正在启动服务...${NC}"

    systemctl daemon-reload
    systemctl enable xray
    systemctl restart xray

    sleep 2

    if systemctl is-active --quiet xray; then
        echo -e "${GREEN}Xray 服务启动成功${NC}"
    else
        echo -e "${RED}Xray 服务启动失败${NC}"
        systemctl status xray
        exit 1
    fi
}

# 配置防火墙
setup_firewall() {
    echo -e "${YELLOW}正在配置防火墙...${NC}"

    if command -v ufw >/dev/null 2>&1; then
        ufw allow ${REALITY_PORT}/tcp
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${REALITY_PORT}/tcp
        firewall-cmd --reload
    fi
}

# 显示配置信息
show_config() {
    local server_ip=$(get_server_ip)
    local vless_link="vless://${REALITY_UUID}@${server_ip}:${REALITY_PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${DEST_SITE}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#Reality-VPN"

    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  VLESS Reality 安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}服务器地址:${NC} ${server_ip}"
    echo -e "${YELLOW}端口:${NC} ${REALITY_PORT}"
    echo -e "${YELLOW}UUID:${NC} ${REALITY_UUID}"
    echo -e "${YELLOW}流控:${NC} xtls-rprx-vision"
    echo -e "${YELLOW}传输协议:${NC} tcp"
    echo -e "${YELLOW}伪装网站:${NC} ${DEST_SITE}"
    echo -e "${YELLOW}Public Key:${NC} ${PUBLIC_KEY}"
    echo -e "${YELLOW}Short ID:${NC} ${SHORT_ID}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}VLESS链接:${NC}"
    echo -e "${BLUE}${vless_link}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}管理命令:${NC}"
    echo -e "启动: ${BLUE}systemctl start xray${NC}"
    echo -e "停止: ${BLUE}systemctl stop xray${NC}"
    echo -e "重启: ${BLUE}systemctl restart xray${NC}"
    echo -e "状态: ${BLUE}systemctl status xray${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 主函数
main() {
    clear
    echo -e "${GREEN}VLESS Reality 一键安装脚本${NC}"
    echo -e "${YELLOW}开始安装...${NC}"

    check_root
    install_dependencies
    get_user_config
    install_xray
    generate_keys
    generate_config
    start_service
    setup_firewall
    show_config
}

# 运行主函数
main
