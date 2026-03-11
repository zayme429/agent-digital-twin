# OpenClaw 连接故障排查指南

## 🚨 当前问题：连接返回 "No response from agent"

### 症状
- ✅ 健康检查端点正常：`curl http://154.9.252.35:3000/health` 返回 `{"ok":true,"status":"running"}`
- ❌ 聊天端点无响应：返回 `{"ok":true,"reply":"No response from agent","sessionId":"http-inbound:test-user"}`
- ⚠️ OpenClaw 日志显示：`[http-inbound:default] health-monitor: hit 3 restarts/hour limit, skipping`
- ⚠️ Gateway 状态：`RPC probe: failed`

### 根本原因
OpenClaw 的健康监控器在 1 小时内重启了 3 次，达到重启限制。Gateway 正在运行，但与核心 Agent 的 RPC 连接失败，导致无法处理聊天请求。

---

## 🔧 修复步骤

### 步骤 1: SSH 登录到 OpenClaw 服务器

```bash
ssh root@154.9.252.35
```

### 步骤 2: 检查 OpenClaw 状态

```bash
# 查看 gateway 状态
openclaw gateway status

# 查看详细日志
openclaw logs --tail 50

# 查看 agent 状态
openclaw agent status
```

### 步骤 3: 重启 OpenClaw Gateway

```bash
# 重启 gateway（这会清除重启计数器）
openclaw gateway restart

# 等待 5-10 秒让服务完全启动
sleep 10

# 验证状态
openclaw gateway status
```

### 步骤 4: 如果 Gateway 重启后仍然失败，重启整个 OpenClaw

```bash
# 完全重启 OpenClaw
openclaw restart

# 等待服务启动
sleep 15

# 检查状态
openclaw status
```

### 步骤 5: 验证连接

```bash
# 测试健康检查
curl http://localhost:3000/health

# 测试聊天功能
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "你好",
    "userId": "test-user"
  }'
```

预期响应：
```json
{
  "ok": true,
  "reply": "你好！有什么我可以帮助你的吗？",
  "sessionId": "http-inbound:test-user"
}
```

---

## 🔍 深度诊断

### 如果重启后仍然失败

#### 1. 检查 RPC 连接

```bash
# 检查 RPC 端口是否监听
netstat -tulpn | grep 18789

# 检查进程
ps aux | grep openclaw
```

#### 2. 检查配置文件

```bash
# 查看 OpenClaw 配置
cat ~/.openclaw/openclaw.json

# 确认 HTTP Inbound Channel 配置正确
```

应该包含：
```json
{
  "channels": {
    "http-inbound": {
      "enabled": true,
      "port": 3000,
      "host": "0.0.0.0",
      "apiKeys": {
        "test-api-key-12345": {
          "name": "Test Client",
          "created": "2026-03-10"
        }
      }
    }
  }
}
```

#### 3. 检查插件状态

```bash
# 列出已安装的插件
openclaw plugins list

# 确认 http-inbound 插件已安装并启用
```

#### 4. 查看完整日志

```bash
# 查看最近的错误日志
openclaw logs --level error --tail 100

# 查看 gateway 日志
openclaw gateway logs --tail 100
```

---

## 🛡️ 预防措施

### 1. 增加健康监控重启限制

编辑 OpenClaw 配置文件 `~/.openclaw/openclaw.json`，添加：

```json
{
  "health": {
    "restart_limit": 10,
    "restart_window": 3600
  }
}
```

### 2. 配置自动重启

如果 OpenClaw 经常崩溃，可以配置 systemd 自动重启：

```bash
# 创建 systemd 服务文件
sudo nano /etc/systemd/system/openclaw.service
```

内容：
```ini
[Unit]
Description=OpenClaw AI Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/openclaw start --daemon=false
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable openclaw
sudo systemctl start openclaw
```

### 3. 监控日志

设置日志轮转以防止日志文件过大：

```bash
# 创建日志轮转配置
sudo nano /etc/logrotate.d/openclaw
```

内容：
```
/var/log/openclaw/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## 📊 常见错误及解决方案

### 错误 1: "health-monitor: hit 3 restarts/hour limit"

**原因**: OpenClaw 在 1 小时内重启了 3 次，达到健康监控限制。

**解决方案**:
1. 重启 gateway 清除计数器：`openclaw gateway restart`
2. 检查导致频繁重启的根本原因（查看日志）
3. 增加重启限制（见预防措施）

### 错误 2: "RPC probe: failed"

**原因**: Gateway 无法连接到 OpenClaw 核心 Agent。

**解决方案**:
1. 检查 RPC 端口是否监听：`netstat -tulpn | grep 18789`
2. 重启整个 OpenClaw：`openclaw restart`
3. 检查防火墙规则：`sudo ufw status`

### 错误 3: "Connection refused"

**原因**: OpenClaw 服务未运行或端口未监听。

**解决方案**:
1. 启动 OpenClaw：`openclaw start`
2. 检查端口：`netstat -tulpn | grep 3000`
3. 检查进程：`ps aux | grep openclaw`

### 错误 4: "Invalid API key"

**原因**: API Key 配置不正确或不匹配。

**解决方案**:
1. 检查配置文件：`cat ~/.openclaw/openclaw.json`
2. 确认 API Key 与后端配置一致
3. 重启 OpenClaw 使配置生效：`openclaw restart`

---

## 🎯 快速修复命令（一键执行）

如果你想快速修复当前问题，在 OpenClaw 服务器上执行：

```bash
# 完整的重启和验证流程
openclaw restart && \
sleep 15 && \
echo "=== OpenClaw Status ===" && \
openclaw status && \
echo "" && \
echo "=== Gateway Status ===" && \
openclaw gateway status && \
echo "" && \
echo "=== Health Check ===" && \
curl -s http://localhost:3000/health && \
echo "" && \
echo "=== Chat Test ===" && \
curl -s -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"message":"你好","userId":"test"}' && \
echo ""
```

---

## 📞 获取帮助

如果以上步骤都无法解决问题：

1. **收集诊断信息**:
   ```bash
   openclaw status > openclaw-status.txt
   openclaw logs --tail 200 > openclaw-logs.txt
   openclaw gateway status > gateway-status.txt
   ```

2. **检查系统资源**:
   ```bash
   free -h  # 内存使用
   df -h    # 磁盘空间
   top -bn1 | head -20  # CPU 使用
   ```

3. **提供以上信息以便进一步诊断**

---

## ✅ 验证修复成功

修复后，确认以下所有检查都通过：

- [ ] `openclaw status` 显示 "running"
- [ ] `openclaw gateway status` 显示 "RPC probe: ok"
- [ ] `curl http://localhost:3000/health` 返回 `{"ok":true,"status":"running"}`
- [ ] 聊天测试返回正常的 AI 回复（不是 "No response from agent"）
- [ ] 后端管理页面测试功能正常（http://localhost:8765 → 🔌 OpenClaw → 发送测试）
- [ ] iOS App 中 OpenClaw 对话功能正常

---

## 📝 总结

当前问题的核心是 OpenClaw 的健康监控器达到重启限制，导致 RPC 连接失败。最简单的解决方案是：

```bash
ssh root@154.9.252.35
openclaw restart
```

等待 15 秒后测试连接即可恢复正常。
