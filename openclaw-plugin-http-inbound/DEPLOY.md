# 部署更新到 OpenClaw 服务器

## 问题修复
修复了 EADDRINUSE 错误（端口 3000 被占用）。现在 `startAccount` 会检查服务器是否已经在运行，避免重复启动。

## 部署步骤

### 方法 1: 使用 tar 包（推荐）

1. 上传压缩包到服务器：
```bash
scp http-inbound-update.tar.gz root@154.9.252.35:/tmp/
```

2. SSH 登录到服务器：
```bash
ssh root@154.9.252.35
# 密码: BtMZf4yGGdR0tGEj
```

3. 解压并更新：
```bash
cd /root/.openclaw/extensions/http-inbound
tar -xzf /tmp/http-inbound-update.tar.gz
npm install
openclaw restart
```

### 方法 2: 直接上传文件

1. 上传更新的文件：
```bash
cd /Users/xiaozijian/WorkSpace/projects/claude_code/xiaoshou_demo_0305/AgentDigitalTwin/openclaw-plugin-http-inbound
scp -r dist src package.json tsconfig.json openclaw.plugin.json root@154.9.252.35:/root/.openclaw/extensions/http-inbound/
```

2. SSH 登录并重启：
```bash
ssh root@154.9.252.35
cd /root/.openclaw/extensions/http-inbound
npm install
openclaw restart
```

## 验证部署

1. 检查 OpenClaw 状态：
```bash
openclaw status
```

2. 检查网关状态：
```bash
openclaw gateway status
```

3. 查看日志（应该只看到一次 "HTTP API server listening"）：
```bash
openclaw logs | grep "http-inbound"
```

4. 测试端口 3000：
```bash
curl http://localhost:3000/health
```

预期响应：
```json
{"ok":true,"status":"running"}
```

## 修复内容

在 `src/channel.ts` 的 `startAccount` 函数中添加了检查：

```typescript
// Check if server is already running
if ((ctx as any).httpServer) {
  console.log("[http-inbound] HTTP server already running, skipping start");
  return;
}
```

这样可以防止多次调用 `startAccount` 时重复绑定端口 3000。
