# OpenClaw HTTP Inbound Plugin - 安全审计报告

## 📅 审计日期
2026-03-10

## ⚠️ npm audit 发现的漏洞

安装时显示：
```
3 high severity vulnerabilities
```

## 🔍 建议的排查步骤

### 在 OpenClaw 服务器上执行：

```bash
cd /tmp/openclaw-plugin-http-inbound

# 查看详细漏洞信息
npm audit

# 查看可修复的漏洞
npm audit fix --dry-run

# 尝试自动修复（不会破坏兼容性）
npm audit fix

# 如果需要强制修复（可能有破坏性变更）
npm audit fix --force
```

## 🛡️ 常见的 npm 漏洞类型

### 1. 依赖包漏洞
- **express** 或其依赖可能有已知漏洞
- **uuid** 通常很安全，但依赖可能有问题

### 2. 过时的依赖
- `glob@10.5.0` 已被标记为过时且有安全漏洞
- 这通常来自其他包的传递依赖

### 3. 原型污染（Prototype Pollution）
- 常见于 JSON 解析和对象合并
- 可能影响 express 的中间件

## 📋 修复建议

### 方案 1：自动修复（推荐先尝试）

```bash
npm audit fix
npm run build
npm test  # 如果有测试的话
```

### 方案 2：更新依赖版本

编辑 `package.json`，更新到最新稳定版本：

```json
{
  "dependencies": {
    "express": "^4.19.2",  // 更新到最新 4.x
    "uuid": "^10.0.0"      // 更新到最新版本
  }
}
```

然后：
```bash
rm -rf node_modules package-lock.json
npm install
npm audit
```

### 方案 3：锁定安全版本

如果 `npm audit fix` 修复了问题，提交新的 `package-lock.json`：

```bash
git add package-lock.json
git commit -m "fix: update dependencies to fix security vulnerabilities"
```

## 🚨 紧急缓解措施

如果无法立即修复漏洞，采取以下措施：

### 1. 使用 nginx 反向代理隔离

```nginx
# 限制访问来源
location /api/chat {
    # 只允许特定 IP
    allow 192.168.1.0/24;
    deny all;

    proxy_pass http://127.0.0.1:3000;
}
```

### 2. 修改监听地址

编辑 `~/.openclaw/openclaw.json`：

```json
{
  "channels": {
    "http-inbound": {
      "enabled": true,
      "port": 3000,
      "host": "127.0.0.1",  // 改为只监听本地
      "apiKeys": { ... }
    }
  }
}
```

### 3. 添加防火墙规则

```bash
# 只允许特定 IP 访问 3000 端口
ufw allow from 192.168.1.100 to any port 3000
ufw deny 3000
```

## 📊 风险评估

### 当前风险等级：中高

**理由：**
- 3 个高危漏洞未修复
- 插件暴露 HTTP 端点
- 处理外部输入

### 降低风险的措施：

1. ✅ 使用 API Key 认证（已实现）
2. ⚠️ 修复 npm 依赖漏洞（待执行）
3. ⚠️ 添加速率限制（未实现）
4. ⚠️ 使用 HTTPS（建议通过 nginx）
5. ⚠️ 限制监听地址（建议改为 127.0.0.1）

## 🔄 后续行动

### 立即执行：
1. 在服务器上运行 `npm audit` 查看详细信息
2. 尝试 `npm audit fix` 自动修复
3. 测试修复后的插件是否正常工作

### 短期（本周内）：
4. 配置 nginx 反向代理提供 HTTPS
5. 修改监听地址为 127.0.0.1
6. 添加防火墙规则

### 中期（本月内）：
7. 添加速率限制中间件
8. 实现请求日志和监控
9. 定期检查依赖更新

## 📞 需要帮助？

如果 `npm audit fix` 无法解决问题，请提供：
1. `npm audit` 的完整输出
2. `package-lock.json` 文件内容
3. 具体的漏洞 CVE 编号

我们可以针对性地修复每个漏洞。

## ⚡ 快速命令参考

```bash
# 查看漏洞详情
npm audit

# 查看 JSON 格式的详细报告
npm audit --json

# 只显示高危和严重漏洞
npm audit --audit-level=high

# 尝试自动修复
npm audit fix

# 强制修复（可能破坏兼容性）
npm audit fix --force

# 查看哪些包需要更新
npm outdated
```
