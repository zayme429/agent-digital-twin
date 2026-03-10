#!/bin/bash

echo "=========================================="
echo "OpenClaw Mock Server 快速测试"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# 启动 Mock Server
echo "1. 启动 Mock Server..."
python3 mock-server.py > /tmp/mock-server.log 2>&1 &
MOCK_PID=$!
echo "   PID: $MOCK_PID"
sleep 3

# 测试健康检查
echo ""
echo "2. 测试健康检查..."
curl -s http://localhost:3000/health
echo ""

# 测试聊天（有效 API Key）
echo ""
echo "3. 测试聊天（有效 API Key）..."
curl -s -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer test-api-key-12345" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello, OpenClaw!","userId":"test-user"}'
echo ""

# 测试无效 API Key
echo ""
echo "4. 测试无效 API Key..."
curl -s -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer wrong-key" \
  -H "Content-Type: application/json" \
  -d '{"message":"Hello","userId":"test"}'
echo ""

# 停止服务器
echo ""
echo "5. 停止 Mock Server..."
kill $MOCK_PID 2>/dev/null
sleep 1

echo ""
echo "=========================================="
echo "测试完成！"
echo "=========================================="
echo ""
echo "查看完整日志："
echo "  cat /tmp/mock-server.log"
