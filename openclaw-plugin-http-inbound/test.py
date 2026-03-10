#!/usr/bin/env python3
"""
OpenClaw HTTP Inbound Channel 测试脚本（Python 版本）
"""

import requests
import json
import sys
from datetime import datetime

# 配置
OPENCLAW_URL = "http://localhost:3000"
API_KEY = "REPLACE-WITH-YOUR-API-KEY"

def print_section(title):
    print("\n" + "=" * 50)
    print(title)
    print("=" * 50 + "\n")

def test_health_check():
    """测试健康检查端点"""
    print("1. 健康检查（无需认证）...")
    try:
        response = requests.get(f"{OPENCLAW_URL}/health")
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 200
    except Exception as e:
        print(f"   错误: {e}")
        return False

def test_chat(message, user_id="test-user", session_id=None):
    """测试聊天端点"""
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    data = {
        "message": message,
        "userId": user_id
    }

    if session_id:
        data["sessionId"] = session_id

    try:
        response = requests.post(
            f"{OPENCLAW_URL}/api/chat",
            headers=headers,
            json=data
        )
        print(f"   状态码: {response.status_code}")
        result = response.json()
        print(f"   响应: {json.dumps(result, indent=2, ensure_ascii=False)}")
        return result
    except Exception as e:
        print(f"   错误: {e}")
        return None

def test_invalid_api_key():
    """测试无效的 API Key"""
    print("3. 测试无效 API Key（应该返回 403）...")
    headers = {
        "Authorization": "Bearer invalid-key-12345",
        "Content-Type": "application/json"
    }

    data = {
        "message": "This should fail",
        "userId": "test-user"
    }

    try:
        response = requests.post(
            f"{OPENCLAW_URL}/api/chat",
            headers=headers,
            json=data
        )
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 403
    except Exception as e:
        print(f"   错误: {e}")
        return False

def test_missing_auth():
    """测试缺少 Authorization header"""
    print("4. 测试缺少 Authorization（应该返回 401）...")
    headers = {
        "Content-Type": "application/json"
    }

    data = {
        "message": "This should fail",
        "userId": "test-user"
    }

    try:
        response = requests.post(
            f"{OPENCLAW_URL}/api/chat",
            headers=headers,
            json=data
        )
        print(f"   状态码: {response.status_code}")
        print(f"   响应: {json.dumps(response.json(), indent=2, ensure_ascii=False)}")
        return response.status_code == 401
    except Exception as e:
        print(f"   错误: {e}")
        return False

def test_session_continuity():
    """测试会话连续性"""
    print("5. 测试会话连续性...")
    session_id = f"test-session-{int(datetime.now().timestamp())}"

    print("   第一条消息...")
    result1 = test_chat(
        "My name is Alice.",
        user_id="alice",
        session_id=session_id
    )

    if not result1 or not result1.get("ok"):
        print("   ❌ 第一条消息失败")
        return False

    print("\n   第二条消息（应该记得我的名字）...")
    result2 = test_chat(
        "What is my name?",
        user_id="alice",
        session_id=session_id
    )

    if not result2 or not result2.get("ok"):
        print("   ❌ 第二条消息失败")
        return False

    # 检查回复中是否包含 "Alice"
    reply = result2.get("reply", "").lower()
    if "alice" in reply:
        print("   ✅ AI 记住了名字！")
        return True
    else:
        print("   ⚠️  AI 可能没有记住名字")
        return False

def main():
    print_section("OpenClaw HTTP Inbound Channel 测试")

    if API_KEY == "REPLACE-WITH-YOUR-API-KEY":
        print("❌ 错误: 请先在脚本中设置正确的 API_KEY")
        print("   编辑 test.py，将 API_KEY 替换为你的实际 API Key")
        sys.exit(1)

    results = []

    # 1. 健康检查
    results.append(("健康检查", test_health_check()))

    # 2. 正常聊天
    print("\n2. 测试聊天...")
    result = test_chat("Hello, OpenClaw! Please introduce yourself.")
    results.append(("正常聊天", result is not None and result.get("ok")))

    # 3. 无效 API Key
    results.append(("无效 API Key", test_invalid_api_key()))

    # 4. 缺少认证
    results.append(("缺少认证", test_missing_auth()))

    # 5. 会话连续性
    results.append(("会话连续性", test_session_continuity()))

    # 总结
    print_section("测试结果总结")
    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✅ 通过" if result else "❌ 失败"
        print(f"{status} - {name}")

    print(f"\n总计: {passed}/{total} 测试通过")

    if passed == total:
        print("\n🎉 所有测试通过！")
        sys.exit(0)
    else:
        print("\n⚠️  部分测试失败，请检查配置和日志")
        sys.exit(1)

if __name__ == "__main__":
    main()
