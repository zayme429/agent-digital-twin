# OpenClaw 集成迁移指南

## 🎯 目标

本指南帮助你将 OpenClaw 集成方案快速迁移到其他 App 中。

## 📋 前提条件

- ☁️ 已有运行中的 OpenClaw 服务器
- ☁️ OpenClaw 服务器上已安装 `openclaw-plugin-http-inbound` 插件
- 🖥️ 你的新 App 有后端服务（或准备添加）
- 📱 你的新 App 需要接入 OpenClaw AI 对话功能

---

## 🚀 快速集成步骤

### 步骤 1: 复制插件代码（如果还未安装）

如果你的 OpenClaw 服务器还没有安装 HTTP Inbound Channel 插件：

```bash
# 🖥️ 在本地机器
# 复制插件目录到你的新项目
cp -r AgentDigitalTwin/openclaw-plugin-http-inbound /path/to/your-new-app/

# 上传到 OpenClaw 服务器
scp -r openclaw-plugin-http-inbound user@your-openclaw-server:/tmp/

# ☁️ SSH 登录到 OpenClaw 服务器
ssh user@your-openclaw-server
cd /tmp/openclaw-plugin-http-inbound
npm install
npm run build
openclaw plugins install .
```

### 步骤 2: 在 OpenClaw 服务器上配置 API Key

```bash
# ☁️ 在 OpenClaw 服务器上执行
nano ~/.openclaw/openclaw.json
```

添加配置：

```json
{
  "channels": {
    "http-inbound": {
      "enabled": true,
      "port": 3000,
      "host": "0.0.0.0",
      "apiKeys": {
        "your-app-api-key-here": {
          "name": "Your New App",
          "created": "2026-03-10"
        }
      }
    }
  }
}
```

重启 OpenClaw：
```bash
# ☁️ 在 OpenClaw 服务器上执行
openclaw restart
```

---

## 🔧 后端集成

### 方案 A: Python 后端

如果你的 App 使用 Python 后端，参考以下代码：

#### 1. 添加配置

在你的配置文件中添加：

```python
# config.py 或 settings.py
OPENCLAW_CONFIG = {
    "enabled": True,
    "url": "http://your-openclaw-server:3000/api/chat",
    "api_keys": [
        {
            "key": "your-app-api-key-here",
            "name": "Your App Client",
            "created": "2026-03-10"
        }
    ]
}
```

#### 2. 添加 API 端点

```python
# app.py 或 main.py
import json
import urllib.request

def openclaw_chat(message, user_id, session_id=None):
    """调用 OpenClaw API"""
    cfg = load_config()  # 从配置文件加载
    openclaw_cfg = cfg.get("openclaw", {})
    url = openclaw_cfg.get("url", "")
    api_keys = openclaw_cfg.get("api_keys", [])

    if not api_keys:
        raise Exception("No API keys configured")

    api_key = api_keys[0].get("key", "")

    data = {
        "message": message,
        "userId": user_id,
        "sessionId": session_id or f"app:{user_id}"
    }

    req_data = json.dumps(data).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=req_data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
    )

    with urllib.request.urlopen(req, timeout=30) as response:
        result = json.loads(response.read().decode('utf-8'))
        return result

# Flask 示例
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/api/chat', methods=['POST'])
def chat():
    data = request.json
    message = data.get('message')
    user_id = data.get('userId', 'anonymous')
    session_id = data.get('sessionId')

    try:
        result = openclaw_chat(message, user_id, session_id)
        return jsonify(result)
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)}), 500

# 添加测试端点
@app.route('/api/openclaw/test', methods=['POST'])
def test_openclaw():
    data = request.json
    message = data.get('message', '测试消息')

    try:
        result = openclaw_chat(message, 'test-user', 'test-session')
        return jsonify({"ok": True, "reply": result.get("reply", ""), "raw": result})
    except Exception as e:
        return jsonify({"ok": False, "error": str(e)})
```

### 方案 B: Node.js 后端

```javascript
// openclaw.js
const axios = require('axios');

const OPENCLAW_CONFIG = {
  enabled: true,
  url: 'http://your-openclaw-server:3000/api/chat',
  apiKeys: [
    {
      key: 'your-app-api-key-here',
      name: 'Your App Client',
      created: '2026-03-10'
    }
  ]
};

async function openclawChat(message, userId, sessionId = null) {
  if (!OPENCLAW_CONFIG.apiKeys || OPENCLAW_CONFIG.apiKeys.length === 0) {
    throw new Error('No API keys configured');
  }

  const apiKey = OPENCLAW_CONFIG.apiKeys[0].key;

  const response = await axios.post(
    OPENCLAW_CONFIG.url,
    {
      message,
      userId,
      sessionId: sessionId || `app:${userId}`
    },
    {
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      timeout: 30000
    }
  );

  return response.data;
}

// Express 示例
const express = require('express');
const app = express();

app.post('/api/chat', async (req, res) => {
  const { message, userId, sessionId } = req.body;

  try {
    const result = await openclawChat(message, userId || 'anonymous', sessionId);
    res.json(result);
  } catch (error) {
    res.status(500).json({ ok: false, error: error.message });
  }
});

// 添加测试端点
app.post('/api/openclaw/test', async (req, res) => {
  const { message } = req.body;

  try {
    const result = await openclawChat(message || '测试消息', 'test-user', 'test-session');
    res.json({ ok: true, reply: result.reply || '', raw: result });
  } catch (error) {
    res.json({ ok: false, error: error.message });
  }
});

module.exports = { openclawChat };
```

### 方案 C: Java/Spring Boot 后端

```java
// OpenClawService.java
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

@Service
public class OpenClawService {

    private static final String OPENCLAW_URL = "http://your-openclaw-server:3000/api/chat";
    private static final String API_KEY = "your-app-api-key-here";

    public Map<String, Object> chat(String message, String userId, String sessionId) {
        RestTemplate restTemplate = new RestTemplate();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "Bearer " + API_KEY);

        Map<String, Object> body = new HashMap<>();
        body.put("message", message);
        body.put("userId", userId);
        body.put("sessionId", sessionId != null ? sessionId : "app:" + userId);

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);

        ResponseEntity<Map> response = restTemplate.postForEntity(
            OPENCLAW_URL,
            request,
            Map.class
        );

        return response.getBody();
    }
}

// ChatController.java
@RestController
@RequestMapping("/api")
public class ChatController {

    @Autowired
    private OpenClawService openClawService;

    @PostMapping("/chat")
    public ResponseEntity<?> chat(@RequestBody ChatRequest request) {
        try {
            Map<String, Object> result = openClawService.chat(
                request.getMessage(),
                request.getUserId(),
                request.getSessionId()
            );
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.status(500)
                .body(Map.of("ok", false, "error", e.getMessage()));
        }
    }
}
```

---

## 📱 客户端集成

### iOS (Swift/SwiftUI)

直接复制以下文件到你的项目：

```bash
# 🖥️ 在本地机器
cp AgentDigitalTwin/AgentDigitalTwin/OpenClawChatView.swift /path/to/your-ios-app/
```

然后在你的 App 中添加入口：

```swift
// 在任意 View 中添加
import SwiftUI

struct YourView: View {
    @State private var showOpenClawChat = false

    var body: some View {
        VStack {
            // 你的其他内容

            Button("OpenClaw 对话") {
                showOpenClawChat = true
            }
        }
        .sheet(isPresented: $showOpenClawChat) {
            OpenClawChatView()
        }
    }
}
```

**重要**: 修改 `OpenClawChatView.swift` 中的后端 URL：

```swift
// 在 OpenClawChatView.swift 中找到这一行：
guard let url = URL(string: "http://localhost:8765/api/openclaw/chat") else {

// 改为你的后端地址：
guard let url = URL(string: "http://your-backend-server/api/chat") else {
```

### Android (Kotlin)

```kotlin
// OpenClawChatActivity.kt
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

class OpenClawService {
    private val client = OkHttpClient()
    private val backendUrl = "http://your-backend-server/api/chat"

    fun sendMessage(
        message: String,
        userId: String,
        sessionId: String?,
        callback: (String?, String?) -> Unit
    ) {
        val json = JSONObject().apply {
            put("message", message)
            put("userId", userId)
            put("sessionId", sessionId ?: "app:$userId")
        }

        val body = json.toString()
            .toRequestBody("application/json".toMediaType())

        val request = Request.Builder()
            .url(backendUrl)
            .post(body)
            .build()

        client.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                callback(null, e.message)
            }

            override fun onResponse(call: Call, response: Response) {
                val responseBody = response.body?.string()
                val jsonResponse = JSONObject(responseBody ?: "{}")

                if (jsonResponse.getBoolean("ok")) {
                    val reply = jsonResponse.getString("reply")
                    val newSessionId = jsonResponse.getString("sessionId")
                    callback(reply, null)
                } else {
                    callback(null, jsonResponse.getString("error"))
                }
            }
        })
    }
}
```

### Web (JavaScript/React)

```javascript
// openclawService.js
export async function sendMessage(message, userId, sessionId = null) {
  const response = await fetch('http://your-backend-server/api/chat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message,
      userId,
      sessionId: sessionId || `app:${userId}`
    })
  });

  if (!response.ok) {
    throw new Error('Network response was not ok');
  }

  return await response.json();
}

// ChatComponent.jsx
import React, { useState } from 'react';
import { sendMessage } from './openclawService';

function OpenClawChat() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [sessionId, setSessionId] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMessage = { role: 'user', content: input };
    setMessages([...messages, userMessage]);
    setInput('');
    setLoading(true);

    try {
      const result = await sendMessage(input, 'web-user', sessionId);

      if (result.ok) {
        const aiMessage = { role: 'assistant', content: result.reply };
        setMessages(prev => [...prev, aiMessage]);
        setSessionId(result.sessionId);
      } else {
        console.error('Error:', result.error);
      }
    } catch (error) {
      console.error('Failed to send message:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="chat-container">
      <div className="messages">
        {messages.map((msg, idx) => (
          <div key={idx} className={`message ${msg.role}`}>
            {msg.content}
          </div>
        ))}
      </div>
      <div className="input-area">
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyPress={(e) => e.key === 'Enter' && handleSend()}
          disabled={loading}
        />
        <button onClick={handleSend} disabled={loading}>
          {loading ? '发送中...' : '发送'}
        </button>
      </div>
    </div>
  );
}

export default OpenClawChat;
```

---

## 🧪 测试集成

### 1. 🖥️ 本地测试（使用 Mock Server）

在集成到真实 OpenClaw 之前，先用 Mock Server 测试：

```bash
# 🖥️ 在本地机器
cd openclaw-plugin-http-inbound
python3 mock-server.py
```

修改你的后端配置，指向 Mock Server：
```
url: http://localhost:3000/api/chat
api_key: test-api-key-12345
```

### 2. 测试后端 API

#### 测试聊天端点
```bash
# 🖥️ 在本地机器测试你的后端
curl -X POST http://your-backend-server/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello",
    "userId": "test-user"
  }'
```

预期响应：
```json
{
  "ok": true,
  "reply": "Hello test-user! I'm a mock OpenClaw server...",
  "sessionId": "http-inbound:test-user"
}
```

#### 测试测试端点（如果实现了）
```bash
curl -X POST http://your-backend-server/api/openclaw/test \
  -H "Content-Type: application/json" \
  -d '{
    "message": "测试消息"
  }'
```

### 3. 📱 测试客户端

在你的 App 中发送测试消息，确认：
- ✅ 消息能成功发送
- ✅ 收到 AI 回复
- ✅ 会话 ID 正确传递
- ✅ 错误处理正常

### 4. 🖥️ 使用后台管理界面测试（推荐）

如果你的后端实现了管理界面（参考 AgentDigitalTwin 的 server.py）：

1. 打开后台管理页面（例如 http://localhost:8765）
2. 进入 OpenClaw 配置页面
3. 配置服务地址和 API Key
4. 使用内置的测试功能发送测试消息
5. 查看返回结果和错误信息

这是最快速的测试方式，无需编写测试脚本。

### 5. ☁️ 切换到生产环境

测试通过后，修改后端配置指向真实 OpenClaw 服务器：
```
url: http://your-openclaw-server:3000/api/chat
api_key: your-real-api-key
```

---

## 🔐 安全建议

### 1. 不要在客户端直接调用 OpenClaw

❌ **错误做法**：
```swift
// 不要这样做！API Key 会暴露在客户端
let url = "http://openclaw-server:3000/api/chat"
request.setValue("Bearer your-api-key", forHTTPHeaderField: "Authorization")
```

✅ **正确做法**：
```swift
// 通过你的后端转发
let url = "http://your-backend-server/api/chat"
// 后端负责添加 API Key
```

### 2. 使用环境变量存储敏感信息

```python
# Python
import os
OPENCLAW_API_KEY = os.environ.get('OPENCLAW_API_KEY')
```

```javascript
// Node.js
const OPENCLAW_API_KEY = process.env.OPENCLAW_API_KEY;
```

```java
// Java
String apiKey = System.getenv("OPENCLAW_API_KEY");
```

### 3. 添加用户认证

在你的后端 API 中添加用户认证，防止未授权访问：

```python
# Python/Flask 示例
from flask import request, jsonify
from functools import wraps

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token or not verify_user_token(token):
            return jsonify({"error": "Unauthorized"}), 401
        return f(*args, **kwargs)
    return decorated

@app.route('/api/chat', methods=['POST'])
@require_auth
def chat():
    # 处理聊天请求
    pass
```

---

## 📊 集成检查清单

完成以下检查确保集成成功：

### ☁️ OpenClaw 服务器端
- [ ] HTTP Inbound Channel 插件已安装
- [ ] API Key 已配置到 `~/.openclaw/openclaw.json`
- [ ] OpenClaw 服务已重启
- [ ] 端口 3000 可从外部访问（或已配置防火墙规则）
- [ ] 健康检查端点正常：`curl http://your-server:3000/health`

### 🖥️ 后端服务器
- [ ] OpenClaw URL 配置正确
- [ ] API Key 配置正确（与 OpenClaw 服务器一致）
- [ ] 后端 API 端点已实现（`/api/chat`）
- [ ] 测试端点已实现（`/api/openclaw/test`，可选但推荐）
- [ ] 错误处理已添加
- [ ] 用户认证已添加（如需要）
- [ ] 本地测试通过（使用 Mock Server）
- [ ] 后台管理界面测试通过（如果实现了）
- [ ] 生产测试通过（连接真实 OpenClaw）

### 📱 客户端
- [ ] 聊天界面已实现
- [ ] 后端 URL 配置正确
- [ ] 消息发送功能正常
- [ ] 消息接收显示正常
- [ ] 会话管理正常
- [ ] 错误提示友好
- [ ] 加载状态显示正常

---

## 🆘 常见问题

### Q: 我的 App 没有后端，可以直接连接 OpenClaw 吗？

A: 不建议。这会暴露 API Key。建议：
1. 创建一个简单的后端服务（可以用 Serverless 函数）
2. 或者使用 Firebase Cloud Functions / AWS Lambda 等
3. 后端负责安全地调用 OpenClaw

### Q: 可以多个 App 共用一个 OpenClaw 服务器吗？

A: 可以！为每个 App 配置不同的 API Key：

```json
{
  "channels": {
    "http-inbound": {
      "apiKeys": {
        "app1-key-abc123": { "name": "App 1", "created": "2026-03-10" },
        "app2-key-def456": { "name": "App 2", "created": "2026-03-10" },
        "app3-key-ghi789": { "name": "App 3", "created": "2026-03-10" }
      }
    }
  }
}
```

每个 App 的后端配置使用各自的 API Key。

### Q: 如何测试 OpenClaw 连接？

A: 推荐以下测试方法（按优先级排序）：

1. **使用后台管理界面测试**（最简单）
   - 如果你的后端实现了管理界面
   - 直接在浏览器中测试，实时查看结果

2. **使用 curl 测试后端 API**
   ```bash
   curl -X POST http://your-backend/api/openclaw/test \
     -H "Content-Type: application/json" \
     -d '{"message":"测试"}'
   ```

3. **使用 Mock Server 测试**
   - 在本地启动 Mock Server
   - 验证后端逻辑是否正确

4. **在客户端 App 中测试**
   - 最后一步，确保端到端流程正常

### Q: 如何实现流式响应（打字机效果）？

A: 当前版本不支持流式响应。如需此功能，需要：
1. 修改 `openclaw-plugin-http-inbound` 插件支持 SSE
2. 修改后端转发 SSE 流
3. 修改客户端处理流式数据

### Q: 如何添加对话历史？

A: OpenClaw 会根据 `sessionId` 自动维护对话历史。确保：
1. 客户端保存 `sessionId`
2. 后续请求带上相同的 `sessionId`
3. 新对话使用新的 `sessionId`

---

## 🎉 完成

现在你已经掌握了如何将 OpenClaw 集成到任何 App 中！

核心要点：
1. ☁️ OpenClaw 服务器安装 HTTP Inbound Channel 插件（一次性）
2. 🖥️ 每个 App 的后端配置自己的 API Key 和转发逻辑
3. 📱 客户端通过后端 API 与 OpenClaw 通信（不直接连接）

如有问题，参考 `OPENCLAW_INTEGRATION.md` 获取更多详细信息。
