#!/bin/bash

# OpenClaw HTTP Inbound Channel 测试脚本

# 配置
OPENCLAW_URL="http://localhost:3000"
API_KEY="REPLACE-WITH-YOUR-API-KEY"

echo "=========================================="
echo "OpenClaw HTTP Inbound Channel 测试"
echo "=========================================="
echo ""

# 1. 健康检查
echo "1. 健康检查（无需认证）..."
curl -s "${OPENCLAW_URL}/health" | jq .
echo ""

# 2. 测试聊天（需要 API Key）
echo "2. 测试聊天..."
curl -s -X POST "${OPENCLAW_URL}/api/chat" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello, OpenClaw! Please introduce yourself.",
    "userId": "test-user-123"
  }' | jq .
echo ""

# 3. 测试无效 API Key
echo "3. 测试无效 API Key（应该返回 403）..."
curl -s -X POST "${OPENCLAW_URL}/api/chat" \
  -H "Authorization: Bearer invalid-key" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "This should fail",
    "userId": "test-user"
  }' | jq .
echo ""

# 4. 测试缺少 Authorization header
echo "4. 测试缺少 Authorization（应该返回 401）..."
curl -s -X POST "${OPENCLAW_URL}/api/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "This should fail",
    "userId": "test-user"
  }' | jq .
echo ""

# 5. 测试会话连续性
echo "5. 测试会话连续性..."
SESSION_ID="test-session-$(date +%s)"

echo "   第一条消息..."
curl -s -X POST "${OPENCLAW_URL}/api/chat" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"My name is Alice.\",
    \"sessionId\": \"${SESSION_ID}\",
    \"userId\": \"alice\"
  }" | jq .
echo ""

echo "   第二条消息（应该记得我的名字）..."
curl -s -X POST "${OPENCLAW_URL}/api/chat" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"message\": \"What is my name?\",
    \"sessionId\": \"${SESSION_ID}\",
    \"userId\": \"alice\"
  }" | jq .
echo ""

echo "=========================================="
echo "测试完成！"
echo "=========================================="
