# OpenClaw HTTP Inbound Channel 安装指南

## 插件已创建完成

插件位置：`openclaw-plugin-http-inbound/`

## 在 OpenClaw 服务器上安装步骤

### 步骤 1：上传插件到服务器

```bash
# 方法 A：使用 Git（推荐）
# 先将插件推送到 GitHub，然后在服务器上：
cd ~
git clone https://github.com/your-username/openclaw-plugin-http-inbound.git

# 方法 B：使用 scp 直接上传
# 在本地执行：
cd /path/to/AgentDigitalTwin
scp -r openclaw-plugin-http-inbound your-server:/home/your-user/
```

### 步骤 2：构建插件

```bash
# 在 OpenClaw 服务器上
cd ~/openclaw-plugin-http-inbound
npm install
npm run build
```

### 步骤 3：安装插件到 OpenClaw

```bash
# 安装插件
openclaw plugins add ~/openclaw-plugin-http-inbound

# 验证安装
openclaw plugins list
# 应该看到 "http-inbound" 在列表中
```

### 步骤 4：配置插件

编辑 OpenClaw 配置文件：

```bash
nano ~/.openclaw/openclaw.json
```

添加以下配置：

```json
{
  "channels": {
    "http-inbound": {
      "enabled": true,
      "port": 3000,
      "host": "0.0.0.0",
      "apiKeys": {
        "agentdigitaltwin-abc123xyz": {
          "name": "AgentDigitalTwin App",
          "created": "2026-03-09",
          "permissions": ["chat.send"]
        }
      }
    }
  },
  "agent": {
    "model": "anthropic/claude-sonnet-4-6"
  }
}
```

**生成 API Key：**

```bash
# 使用 OpenSSL 生成随机 key
openssl rand -hex 32
# 输出示例：a1b2c3d4e5f6...（64个字符）

# 或使用 Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

将生成的 key 替换上面配置中的 `agentdigitaltwin-abc123xyz`。

### 步骤 5：启用 channel

```bash
# 添加 channel
openclaw channels add http-inbound

# 查看状态
openclaw channels status
```

### 步骤 6：重启 OpenClaw Gateway

```bash
# 重启 gateway
openclaw gateway restart

# 或者如果是首次启动
openclaw gateway --port 18789 --verbose
```

### 步骤 7：测试连接

```bash
# 健康检查（无需认证）
curl http://localhost:3000/health

# 应该返回：
# {"ok":true,"status":"running"}

# 测试聊天（需要 API Key）
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer agentdigitaltwin-abc123xyz" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, OpenClaw!",
    "userId": "test-user"
  }'

# 应该返回 AI 回复：
# {"ok":true,"reply":"AI response here","sessionId":"http-inbound:test-user"}
```

## 防火墙配置（如果需要外部访问）

```bash
# 允许端口 3000（根据你的配置）
sudo ufw allow 3000/tcp

# 或者只允许特定 IP
sudo ufw allow from YOUR_LOCAL_IP to any port 3000
```

## 故障排查

### 插件未加载

```bash
# 查看插件列表
openclaw plugins list

# 查看详细日志
openclaw gateway --verbose
```

### 端口被占用

修改配置中的 `port` 为其他端口（如 3001, 8080）。

### API Key 无效

- 确认 key 已添加到 `~/.openclaw/openclaw.json`
- 重启 gateway 使配置生效
- 检查 `Authorization` header 格式：`Bearer <key>`

### 无法从外部访问

- 检查 `host` 配置是否为 `"0.0.0.0"`（允许外部访问）
- 检查防火墙规则
- 检查服务器安全组设置（云服务器）

## 下一步

安装完成后，你可以：

1. 在你的后端配置页面填入：
   - OpenClaw URL: `http://your-server:3000/api/chat`
   - API Key: `agentdigitaltwin-abc123xyz`（你生成的 key）

2. 测试连接

3. 开始使用！

## 卸载插件

```bash
# 禁用 channel
openclaw channels remove http-inbound

# 卸载插件
openclaw plugins remove http-inbound

# 删除文件
rm -rf ~/openclaw-plugin-http-inbound
```
