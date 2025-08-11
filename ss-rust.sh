#!/bin/bash

# Shadowsocks-Rust 一键安装脚本
# 自定义版本 - 支持多种加密方式和优化配置

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

# 检测系统架构
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64) echo "x86_64" ;;
        aarch64) echo "aarch64" ;;
        armv7l) echo "armv7" ;;
        *) echo "x86_64" ;;
    esac
}

# 安装依赖
install_dependencies() {
    echo -e "${YELLOW}正在安装依赖包...${NC}"

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y curl wget unzip jq
    elif command -v yum >/dev/null 2>&1; then
        yum update -y
        yum install -y curl wget unzip jq epel-release
    else
        echo -e "${RED}不支持的系统类型${NC}"
        exit 1
    fi
}

# 用户输入配置
get_user_config() {
    echo -e "${BLUE}=== Shadowsocks-Rust 配置 ===${NC}"

    # 端口配置
    while true; do
        read -p "请输入端口号 (1-65535, 默认随机): " SS_PORT
        if [[ -z "$SS_PORT" ]]; then
            SS_PORT=$(shuf -i 10000-65000 -n 1)
            break
        elif [[ "$SS_PORT" =~ ^[0-9]+$ ]] && [ "$SS_PORT" -ge 1 ] && [ "$SS_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}请输入有效的端口号 (1-65535)${NC}"
        fi
    done

    # 密码配置
    read -p "请输入密码 (留空自动生成): " SS_PASSWORD
    if [[ -z "$SS_PASSWORD" ]]; then
        SS_PASSWORD=$(openssl rand -base64 16 2>/dev/null || cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
    fi

    # 加密方式选择
    echo -e "${YELLOW}请选择加密方式:${NC}"
    echo "1) aes-256-gcm (推荐)"
    echo "2) aes-128-gcm"
    echo "3) chacha20-ietf-poly1305"
    echo "4) xchacha20-ietf-poly1305"

    while true; do
        read -p "请选择 (1-4, 默认1): " method_choice
        case ${method_choice:-1} in
            1) SS_METHOD="aes-256-gcm"; break ;;
            2) SS_METHOD="aes-128-gcm"; break ;;
            3) SS_METHOD="chacha20-ietf-poly1305"; break ;;
            4) SS_METHOD="xchacha20-ietf-poly1305"; break ;;
            *) echo -e "${RED}请输入有效选项 (1-4)${NC}" ;;
        esac
    done
}

# 下载并安装Shadowsocks-Rust
install_shadowsocks() {
    echo -e "${YELLOW}正在下载 Shadowsocks-Rust...${NC}"

    local arch=$(detect_arch)
    local latest_version=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | jq -r '.tag_name')

    if [[ -z "$latest_version" ]]; then
        echo -e "${RED}获取最新版本失败${NC}"
        exit 1
    fi

    local download_url="https://github.com/shadowsocks/shadowsocks-rust/releases/download/${latest_version}/shadowsocks-${latest_version}.${arch}-unknown-linux-gnu.tar.xz"

    cd /tmp
    wget -O shadowsocks.tar.xz "$download_url" || {
        echo -e "${RED}下载失败${NC}"
        exit 1
    }

    tar -xf shadowsocks.tar.xz
    chmod +x ss*
    mv ssserver /usr/local/bin/
    rm -f ss* shadowsocks.tar.xz

    echo -e "${GREEN}Shadowsocks-Rust 安装完成${NC}"
}

# 生成配置文件
generate_config() {
    echo -e "${YELLOW}正在生成配置文件...${NC}"

    mkdir -p /etc/shadowsocks-rust

    cat > /etc/shadowsocks-rust/config.json << EOF
{
    "server": "::",
    "server_port": ${SS_PORT},
    "password": "${SS_PASSWORD}",
    "method": "${SS_METHOD}",
    "timeout": 300,
    "fast_open": true,
    "mode": "tcp_and_udp"
}
EOF
}

# 创建系统服务
create_service() {
    echo -e "${YELLOW}正在创建系统服务...${NC}"

    cat > /etc/systemd/system/shadowsocks-rust.service << EOF
[Unit]
Description=Shadowsocks-Rust Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks-rust/config.json
Restart=on-failure
RestartSec=5
LimitNOFILE=32768

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable shadowsocks-rust
    systemctl start shadowsocks-rust
}

# 配置防火墙
setup_firewall() {
    echo -e "${YELLOW}正在配置防火墙...${NC}"

    if command -v ufw >/dev/null 2>&1; then
        ufw allow ${SS_PORT}/tcp
        ufw allow ${SS_PORT}/udp
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=${SS_PORT}/tcp
        firewall-cmd --permanent --add-port=${SS_PORT}/udp
        firewall-cmd --reload
    fi
}

# 显示配置信息
show_config() {
    local server_ip=$(get_server_ip)
    local ss_link=$(echo -n "${SS_METHOD}:${SS_PASSWORD}@${server_ip}:${SS_PORT}" | base64 -w 0)

    clear
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Shadowsocks-Rust 安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}服务器地址:${NC} ${server_ip}"
    echo -e "${YELLOW}端口:${NC} ${SS_PORT}"
    echo -e "${YELLOW}密码:${NC} ${SS_PASSWORD}"
    echo -e "${YELLOW}加密方式:${NC} ${SS_METHOD}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}SS链接:${NC}"
    echo -e "${BLUE}ss://${ss_link}${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${YELLOW}管理命令:${NC}"
    echo -e "启动: ${BLUE}systemctl start shadowsocks-rust${NC}"
    echo -e "停止: ${BLUE}systemctl stop shadowsocks-rust${NC}"
    echo -e "重启: ${BLUE}systemctl restart shadowsocks-rust${NC}"
    echo -e "状态: ${BLUE}systemctl status shadowsocks-rust${NC}"
    echo -e "${GREEN}========================================${NC}"
}

# 主函数
main() {
    clear
    echo -e "${GREEN}Shadowsocks-Rust 一键安装脚本${NC}"
    echo -e "${YELLOW}开始安装...${NC}"

    check_root
    install_dependencies
    get_user_config
    install_shadowsocks
    generate_config
    create_service
    setup_firewall
    show_config
}

# 运行主函数
main
