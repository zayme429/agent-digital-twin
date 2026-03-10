# Mock OpenClaw Server - 本地测试指南

## 🎯 目的

在不连接真实 OpenClaw 服务器的情况下，本地测试 HTTP Inbound Channel 的功能。

## 🚀 快速开始

### 1. 启动 Mock Server

```bash
cd openclaw-plugin-http-inbound
python3 mock-server.py
```

你会看到：
```
============================================================
Mock OpenClaw HTTP Inbound Server
============================================================

Server starting on http://localhost:3000

Configured API Keys:
  - test-api-key-12345 (Test Client)

Endpoints:
  GET  http://localhost:3000/health
  POST http://localhost:3000/api/chat

Press Ctrl+C to stop

============================================================
```

### 2. 运行测试脚本

**打开新的终端窗口**，运行测试：

```bash
cd openclaw-plugin-http-inbound

# 修改测试脚本中的 API Key
# 编辑 test.sh 或 test.py，将 API_KEY 改为：
# API_KEY="test-api-key-12345"

# 运行测试
./test.sh
# 或
python3 test.py
```

### 3. 手动测试

```bash
# 健康检查
curl http://localhost:3000/health

# 发送消息
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, OpenClaw!",
    "userId": "test-user"
  }'

# 测试会话连续性
SESSION_ID="test-session-123"

curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"My name is Alice.\",
    \"sessionId\": \"${SESSION_ID}\",
    \"userId\": \"alice\"
  }"

curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"What is my name?\",
    \"sessionId\": \"${SESSION_ID}\",
    \"userId\": \"alice\"
  }"
```

## 🧪 Mock Server 功能

### 已实现的功能

- ✅ API Key 认证（Bearer Token）
- ✅ 健康检查端点
- ✅ 聊天端点
- ✅ 错误处理（401, 403, 400, 404）
- ✅ 简单的规则匹配回复
- ✅ Session ID 处理

### Mock 回复规则

Mock Server 会根据消息内容返回不同的回复：

| 消息内容 | 回复 |
|---------|------|
| "hello", "hi", "你好" | 问候回复 |
| "My name is X" | 记住名字的回复 |
| "What is my name?" | 说明这是 mock server |
| "weather" | 天气相关的测试回复 |
| "introduce", "who are you" | 自我介绍 |
| 其他 | 回显消息内容 |

### 限制

Mock Server **不会**真正记住上下文（因为没有真实的 AI 模型），但它可以：
- 验证 API 认证流程
- 测试请求/响应格式
- 验证错误处理
- 测试基本的 HTTP 通信

## 🔧 自定义 Mock Server

### 添加新的 API Key

编辑 `mock-server.py`：

```python
API_KEYS = {
    "test-api-key-12345": {
        "name": "Test Client",
        "created": "2026-03-09"
    },
    "your-new-key": {
        "name": "Your App",
        "created": "2026-03-09"
    }
}
```

### 修改端口

```python
PORT = 3001  # 改为其他端口
```

### 添加自定义回复规则

在 `generate_mock_reply()` 方法中添加：

```python
elif 'custom' in message_lower:
    return "Your custom response here"
```

## 📝 测试场景

### 场景 1：基本通信测试

```bash
# 启动 mock server
python3 mock-server.py

# 在另一个终端
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello!", "userId": "test"}'
```

**预期结果：**
```json
{
  "ok": true,
  "reply": "Hello test! I'm a mock OpenClaw server...",
  "sessionId": "http-inbound:test"
}
```

### 场景 2：认证失败测试

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer wrong-key" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "userId": "test"}'
```

**预期结果：**
```json
{
  "ok": false,
  "error": "Invalid API key"
}
```

### 场景 3：缺少认证测试

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "userId": "test"}'
```

**预期结果：**
```json
{
  "ok": false,
  "error": "Missing or invalid Authorization header"
}
```

## 🔄 集成到你的后端测试

### Python 示例

```python
import requests

OPENCLAW_URL = "http://localhost:3000/api/chat"
API_KEY = "test-api-key-12345"

def chat_with_openclaw(message, user_id):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    data = {
        "message": message,
        "userId": user_id
    }

    response = requests.post(OPENCLAW_URL, json=data, headers=headers)
    return response.json()

# 测试
result = chat_with_openclaw("Hello!", "user-123")
print(result)
```

## ✅ 验证清单

使用 Mock Server 验证以下功能：

- [ ] 健康检查端点正常工作
- [ ] API Key 认证成功
- [ ] 无效 API Key 返回 403
- [ ] 缺少 Authorization 返回 401
- [ ] 消息发送成功并收到回复
- [ ] Session ID 正确处理
- [ ] 错误响应格式正确
- [ ] 你的后端能成功调用 Mock Server

## 🎉 下一步

Mock Server 测试通过后：

1. ✅ 确认 HTTP Inbound Channel 插件设计正确
2. ✅ 验证你的后端集成代码工作正常
3. ⏭️ 在真实 OpenClaw 服务器上安装插件
4. ⏭️ 使用真实 AI 模型测试

## 🛑 停止 Mock Server

在运行 Mock Server 的终端按 `Ctrl+C`。
