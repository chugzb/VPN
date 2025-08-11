# VPN 一键安装脚本集合

本仓库由「雷豹云」维护，提供多种VPN协议的一键安装脚本。官网：https://hx.dxclouds.com/

## 支持的协议

### 1. Shadowsocks-Rust
- **文件**: `ss-rust.sh`
- **协议**: Shadowsocks
- **加密**: aes-128-gcm
- **特点**: 高性能Rust实现，支持TCP+UDP

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/chugzb/VPN/main/ss-rust.sh)
```

### 2. VLESS Reality
- **文件**: `reality.sh`
- **协议**: VLESS + Reality
- **特点**: 最新的反审查技术，高度隐蔽
- **默认端口**: 443
- **默认SNI**: www.amazon.com

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/chugzb/VPN/main/reality.sh)
```

### 3. VMess WebSocket
- **文件**: `ws.sh`
- **协议**: VMess + WebSocket
- **加密**: aes-128-gcm
- **特点**: 适合CDN中转

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/chugzb/VPN/main/ws.sh)
```

### 4. Hysteria2
- **文件**: `hy2.sh`
- **协议**: Hysteria2
- **特点**: 基于QUIC的高速代理协议

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/chugzb/VPN/main/hy2.sh)
```

### 5. TCP+WSS 双协议
- **文件**: `tcp-wss.sh`
- **协议**: VLESS TCP + VMess WSS
- **特点**: 同时支持两种协议

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/chugzb/VPN/main/tcp-wss.sh)
```

## 辅助脚本

### HTTPS 伪装
- **文件**: `https.sh`
- **功能**: 为代理服务添加HTTPS伪装

### TCP 窗口优化
- **文件**: `tcp-window.sh`
- **功能**: 优化系统TCP参数，提升网络性能

## 使用说明

1. **系统要求**: Ubuntu 18+, Debian 9+, CentOS 7+
2. **权限要求**: 需要root权限
3. **网络要求**: 服务器需要能够访问外网

## 安装步骤

1. 选择合适的协议脚本
2. 复制对应的安装命令
3. 在服务器上执行命令
4. 按照提示完成配置
5. 获取客户端配置信息

## 客户端推荐

- **Windows**: v2rayN, Clash for Windows
- **Android**: v2rayNG, Clash for Android
- **iOS**: Shadowrocket, Quantumult X
- **macOS**: ClashX, V2rayU

## 注意事项

- 安装前请确保服务器时区正确
- 建议定期更新脚本和软件版本
- 请遵守当地法律法规
- 仅供学习和研究使用

## 故障排除

### 常见问题

1. **端口被占用**: 检查防火墙设置和端口占用情况
2. **连接失败**: 确认服务器IP和端口配置正确
3. **速度慢**: 尝试使用TCP窗口优化脚本

### 服务管理命令

```bash
# 查看服务状态
systemctl status [服务名]

# 重启服务
systemctl restart [服务名]

# 查看日志
journalctl -u [服务名] -f
```

## 更新日志

- 初始版本发布
- 支持多种主流代理协议
- 提供完整的安装和配置脚本

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进这些脚本。
