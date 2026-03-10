#!/usr/bin/env python3
"""
Mock OpenClaw Server - 用于本地测试
模拟 OpenClaw HTTP Inbound Channel 的行为
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
from urllib.parse import urlparse

PORT = 3000
API_KEYS = {
    "test-api-key-12345": {
        "name": "Test Client",
        "created": "2026-03-09"
    }
}

class MockOpenClawHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', len(body))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_GET(self):
        path = urlparse(self.path).path

        if path == '/health':
            self.send_json({"ok": True, "status": "running"})
        else:
            self.send_json({"ok": False, "error": "Not found"}, 404)

    def do_POST(self):
        path = urlparse(self.path).path

        if path == '/api/chat':
            # 验证 API Key
            auth_header = self.headers.get('Authorization', '')
            if not auth_header.startswith('Bearer '):
                self.send_json({"ok": False, "error": "Missing or invalid Authorization header"}, 401)
                return

            api_key = auth_header[7:]  # Remove "Bearer "
            if api_key not in API_KEYS:
                self.send_json({"ok": False, "error": "Invalid API key"}, 403)
                return

            # 读取请求体
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            try:
                data = json.loads(body)
            except json.JSONDecodeError:
                self.send_json({"ok": False, "error": "Invalid JSON"}, 400)
                return

            message = data.get('message')
            if not message:
                self.send_json({"ok": False, "error": "Missing 'message' field"}, 400)
                return

            user_id = data.get('userId', 'anonymous')
            session_id = data.get('sessionId', f'http-inbound:{user_id}')

            # 模拟 AI 回复
            reply = self.generate_mock_reply(message, user_id)

            self.send_json({
                "ok": True,
                "reply": reply,
                "sessionId": session_id
            })
        else:
            self.send_json({"ok": False, "error": "Not found"}, 404)

    def generate_mock_reply(self, message, user_id):
        """生成模拟的 AI 回复"""
        message_lower = message.lower()

        # 简单的规则匹配
        if 'hello' in message_lower or '你好' in message_lower or 'hi' in message_lower:
            return f"Hello {user_id}! I'm a mock OpenClaw server. How can I help you today?"

        elif 'name' in message_lower and ('my' in message_lower or 'is' in message_lower):
            # 提取名字（简单实现）
            words = message.split()
            if 'is' in words:
                idx = words.index('is')
                if idx + 1 < len(words):
                    name = words[idx + 1].rstrip('.')
                    return f"Nice to meet you, {name}! I'll remember your name."
            return "Nice to meet you! What's your name?"

        elif 'what' in message_lower and 'name' in message_lower:
            return "I'm a mock OpenClaw server for testing purposes. In a real setup, I would remember context from previous messages."

        elif 'weather' in message_lower:
            return "I'm a mock server, so I don't have real weather data. But I can tell you it's always sunny in the world of testing! ☀️"

        elif 'introduce' in message_lower or 'who are you' in message_lower:
            return "I'm a mock OpenClaw server running locally for testing. I simulate the HTTP Inbound Channel plugin behavior, including API key authentication and basic conversation responses."

        elif 'test' in message_lower:
            return "Test received! Everything is working correctly. This is a mock response from the OpenClaw simulator."

        else:
            return f"I received your message: '{message}'. This is a mock response from the OpenClaw test server. In production, this would be processed by a real AI model."

def main():
    print("=" * 60)
    print("Mock OpenClaw HTTP Inbound Server")
    print("=" * 60)
    print(f"\nServer starting on http://localhost:{PORT}")
    print(f"\nConfigured API Keys:")
    for key, config in API_KEYS.items():
        print(f"  - {key} ({config['name']})")
    print(f"\nEndpoints:")
    print(f"  GET  http://localhost:{PORT}/health")
    print(f"  POST http://localhost:{PORT}/api/chat")
    print(f"\nPress Ctrl+C to stop\n")
    print("=" * 60)

    server = HTTPServer(('127.0.0.1', PORT), MockOpenClawHandler)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        server.shutdown()
        print("Server stopped.")

if __name__ == '__main__':
    main()
