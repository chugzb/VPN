# 2025 快速搭建个人VPN科学上网（保姆级教程）

## 🚀 简介

本教程将手把手教你在2025年快速搭建属于自己的VPN服务器，实现科学上网。支持多种协议，稳定高速，适合个人使用。

## 📋 准备工作

### 1. 服务器要求
- **推荐VPS提供商**：
  - **雷豹云**（首选推荐，高性价比，稳定可靠）- [点击注册](https://hx.dxclouds.com/index/index/login)
  - DigitalOcean（国外老牌）
  - Linode（技术稳定）
  - 搬瓦工（中文友好）

- **服务器配置**：
  - 内存：1GB以上
  - 硬盘：20GB以上
  - 带宽：不限流量
  - 系统：Ubuntu 20.04/22.04 LTS 或 CentOS 8

### 2. 域名（可选但推荐）
- 购买一个域名用于伪装
- 推荐：Cloudflare、Namecheap、GoDaddy

## 🎯 雷豹云服务器购买指南

### 为什么选择雷豹云？
- ✅ **高性价比**：价格实惠，配置优秀
- ✅ **网络稳定**：多线BGP，延迟低
- ✅ **中文服务**：客服支持，操作简单
- ✅ **快速部署**：秒级开通，即买即用
- ✅ **安全可靠**：正规IDC，数据安全

### 购买步骤
1. **注册账号**：访问 [雷豹云官网](https://hx.dxclouds.com/index/index/login)
2. **选择套餐**：推荐选择海外VPS（香港/美国/日本节点）
3. **配置选择**：
   - CPU：1核心
   - 内存：1GB
   - 硬盘：20GB SSD
   - 带宽：1-5Mbps
   - 系统：CentOS 8 或 Ubuntu 20.04
4. **完成支付**：支持支付宝、微信支付
5. **获取信息**：记录服务器IP、用户名、密码

## 🛠️ 安装方法

### 方法一：一键脚本安装（推荐新手）

#### 1. 连接服务器
```bash
ssh root@your_server_ip
```

#### 2. 安装必要的库
```bash
# CentOS系统
sudo yum -y install wget gcc gcc-c++ autoconf automake make

# Ubuntu系统
sudo apt-get update
sudo apt-get -y install wget gcc g++ autoconf automake make
```

#### 3. 下载安装脚本
```bash
wget --no-check-certificate -O ss.sh https://raw.githubusercontent.com/sucong426/VPN/main/ss.sh
```

#### 4. 执行脚本
```bash
sh ss.sh
```

#### 5. 配置参数
- 设置VPN密码（自定义）
- 设置端口（默认回车即可）
- 选择加密方式（推荐选择7：aes-256-gcm）

### 方法二：X-UI面板（可视化管理）

#### 1. 安装X-UI
```bash
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
```

#### 2. 配置面板
- 访问：`http://your_server_ip:54321`
- 默认用户名：admin
- 默认密码：admin

#### 3. 添加节点
1. 进入面板 → 入站列表 → 添加入站
2. 选择协议：VLESS + TCP + TLS
3. 设置端口：443
4. 配置域名和证书

### 方法三：V2Ray一键脚本

#### 1. 安装脚本
```bash
bash <(curl -s -L https://git.io/v2ray.sh)
```

#### 2. 选择配置
- 选择传输协议：WebSocket + TLS
- 设置伪装域名
- 自动申请SSL证书

## 📱 客户端配置

### Windows系统
- **推荐客户端**：
  - [Shadowsocks Windows](https://github.com/shadowsocks/shadowsocks-windows/releases) - 简单易用
  - [V2rayN](https://github.com/2dust/v2rayN/releases) - 功能强大
  - [Clash for Windows](https://github.com/Fndroid/clash_for_windows_pkg/releases) - 规则丰富

### Android系统
- **推荐客户端**：
  - [Shadowsocks Android](https://github.com/shadowsocks/shadowsocks-android/releases)
  - [V2rayNG](https://github.com/2dust/v2rayNG/releases)
  - [Clash for Android](https://github.com/Kr328/ClashForAndroid/releases)

### iOS系统
- **推荐客户端**：
  - Shadowrocket（小火箭）- App Store付费
  - Quantumult X - App Store付费
  - Surge - App Store付费
- **注意**：需要外区Apple ID账号

### macOS系统
- **推荐客户端**：
  - [ClashX](https://github.com/yichengchen/clashX/releases)
  - [V2rayU](https://github.com/yanue/V2rayU/releases)
  - [ShadowsocksX-NG](https://github.com/shadowsocks/ShadowsocksX-NG/releases)

### 配置说明
安装完成后，你会得到以下信息：
- **服务器地址**：你的VPS IP地址
- **端口**：默认或自定义端口
- **密码**：你设置的密码
- **加密方式**：选择的加密算法

将这些信息填入客户端即可使用。

## 🔧 优化配置

### 1. BBR加速（提升网络性能）
```bash
# 检查是否支持BBR
lsmod | grep bbr

# 开启BBR加速
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
sysctl -p

# 验证BBR是否开启
sysctl net.ipv4.tcp_congestion_control
```

### 2. 防火墙配置
```bash
# Ubuntu/Debian系统
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 你的SS端口/tcp
ufw enable

# CentOS系统
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=你的SS端口/tcp
firewall-cmd --reload
```

### 3. 服务管理
```bash
# 查看SS服务状态
systemctl status shadowsocks

# 启动/停止/重启服务
systemctl start shadowsocks
systemctl stop shadowsocks
systemctl restart shadowsocks

# 设置开机自启
systemctl enable shadowsocks
```

### 4. 定时重启（可选）
```bash
# 添加定时任务
crontab -e
# 每天凌晨3点重启服务
0 3 * * * systemctl restart shadowsocks
```

## 🛡️ 安全建议

1. **定期更新系统**
```bash
apt update && apt upgrade -y
```

2. **修改SSH端口**
```bash
# 编辑SSH配置
nano /etc/ssh/sshd_config
# 修改Port 22为其他端口
systemctl restart ssh
```

3. **使用密钥登录**
```bash
# 生成密钥对
ssh-keygen -t rsa -b 4096
# 上传公钥到服务器
ssh-copy-id root@your_server_ip
```

4. **设置复杂密码**
- 使用强密码
- 定期更换
- 避免使用默认密码

## 🔍 故障排除

### 常见问题及解决方案

#### 1. 连接超时/无法连接
**可能原因**：
- 服务器防火墙阻止
- 端口未正确开放
- 服务未启动

**解决方法**：
```bash
# 检查服务状态
systemctl status shadowsocks

# 检查端口是否监听
netstat -tlnp | grep 你的端口号

# 重启服务
systemctl restart shadowsocks

# 检查防火墙
iptables -L
```

#### 2. 速度慢/延迟高
**解决方法**：
- 开启BBR加速（见上方优化配置）
- 更换服务器节点（选择距离更近的）
- 检查本地网络环境
- 尝试更换端口

#### 3. 客户端无法连接
**检查项目**：
- 服务器IP地址是否正确
- 端口号是否正确
- 密码是否正确
- 加密方式是否匹配

#### 4. 服务异常停止
```bash
# 查看错误日志
journalctl -u shadowsocks -f

# 检查配置文件
cat /etc/shadowsocks.json

# 手动启动测试
ss-server -c /etc/shadowsocks.json
```

### 日志查看
```bash
# Shadowsocks日志
tail -f /var/log/shadowsocks.log

# 系统日志
journalctl -u shadowsocks -f

# 实时监控连接
ss -tlnp | grep 你的端口
```

### 测试连接
```bash
# 测试端口连通性
telnet 你的服务器IP 你的端口

# 测试网络延迟
ping 你的服务器IP
```

## 📊 性能监控

### 安装监控工具
```bash
# 安装htop
apt install htop

# 安装iftop（网络监控）
apt install iftop

# 查看实时流量
iftop -i eth0
```

## 🎯 进阶配置

### 1. CDN加速
- 使用Cloudflare CDN
- 配置Workers脚本
- 实现流量中转

### 2. 负载均衡
- 配置多个后端服务器
- 实现故障转移
- 提高可用性

### 3. 流量统计
- 配置流量监控
- 设置使用限制
- 生成统计报告

## 🎯 使用教程

### 安装成功后的信息
脚本执行完成后，会显示类似以下信息：
```
Congratulations, Shadowsocks-libev server install completed!
Your Server IP        : 你的服务器IP
Your Server Port      : 你设置的端口
Your Password         : 你设置的密码
Your Encryption Method: aes-256-gcm

Welcome to visit: https://teddysun.com/486.html
Enjoy it!
```

### 客户端配置步骤
1. **下载对应客户端**（见上方客户端配置）
2. **添加服务器配置**：
   - 服务器：你的VPS IP地址
   - 端口：显示的端口号
   - 密码：你设置的密码
   - 加密：选择的加密方式
3. **连接测试**：启动代理，访问 Google 测试

### 速度测试
连接成功后可以访问：
- [Google](https://www.google.com) - 测试基本连接
- [YouTube](https://www.youtube.com) - 测试视频流畅度
- [Speedtest](https://www.speedtest.net) - 测试网络速度

## 💡 进阶技巧

### 1. 多端口配置
```bash
# 编辑配置文件支持多端口
nano /etc/shadowsocks.json
```

### 2. 流量统计
```bash
# 安装vnstat监控流量
yum install vnstat -y
vnstat -i eth0
```

### 3. 自动化脚本
创建管理脚本方便日常维护：
```bash
#!/bin/bash
# SS管理脚本
case "$1" in
    start)
        systemctl start shadowsocks
        ;;
    stop)
        systemctl stop shadowsocks
        ;;
    restart)
        systemctl restart shadowsocks
        ;;
    status)
        systemctl status shadowsocks
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        ;;
esac
```

## ⚠️ 重要提醒

### 安全建议
1. **定期更换密码**：建议每月更换一次
2. **使用强密码**：包含大小写字母、数字、特殊字符
3. **限制访问**：只允许必要的IP访问
4. **定期备份**：备份配置文件和重要数据

### 法律声明
本教程仅供学习和技术研究使用，请遵守当地法律法规。使用本教程所产生的任何后果，作者不承担任何责任。

## 🤝 支持项目

如果这个教程对你有帮助：
- ⭐ 给项目点个Star
- 🍴 Fork项目支持
- 📝 提交Issue反馈问题
- 💡 贡献代码和文档

## 📞 获取帮助

- **GitHub Issues**：[提交问题](https://github.com/your-repo/issues)
- **讨论交流**：欢迎在Issues中交流经验
- **更新通知**：Watch项目获取最新更新

---

**🎉 祝你使用愉快！科学上网，理性使用！**

*最后更新：2025年1月*
