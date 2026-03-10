# HTTP Inbound Channel for OpenClaw

A channel plugin that allows custom applications to connect to OpenClaw via HTTP REST API with API key authentication.

## Features

- 🔐 **API Key Authentication** - Secure access with individual API keys for each client application
- 🚀 **Simple REST API** - Easy integration with any HTTP client
- 🔒 **Permission Isolation** - Each API key has isolated access, cannot interfere with other channels
- 📝 **Session Management** - Automatic session handling per user/client
- ⚡ **Synchronous Responses** - Get AI replies immediately in the HTTP response

## Installation

### Method 1: Install from local directory

```bash
# On your OpenClaw server
cd /path/to/openclaw-plugin-http-inbound
npm install
npm run build

# Install the plugin
openclaw plugins install .
```

### Method 2: Install from Git repository

```bash
# Clone the repository
git clone https://github.com/your-username/openclaw-plugin-http-inbound.git
cd openclaw-plugin-http-inbound
npm install
npm run build

# Install to OpenClaw
openclaw plugins install .
```

### Method 3: Install from npm (if published)

```bash
openclaw plugins install @openclaw/plugin-http-inbound
```

## Configuration

### 1. Add the channel to your OpenClaw config

Edit `~/.openclaw/openclaw.json`:

```json
{
  "channels": {
    "http-inbound": {
      "enabled": true,
      "port": 3000,
      "host": "0.0.0.0",
      "apiKeys": {
        "agentdigitaltwin-key-abc123": {
          "name": "AgentDigitalTwin App",
          "created": "2026-03-09",
          "permissions": ["chat.send"]
        },
        "another-app-key-xyz789": {
          "name": "Another Custom App",
          "created": "2026-03-10",
          "permissions": ["chat.send"]
        }
      }
    }
  }
}
```

### 2. Enable the channel

```bash
openclaw channels add http-inbound
openclaw channels status
```

### 3. Restart OpenClaw Gateway

```bash
openclaw gateway restart
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `true` | Enable/disable the HTTP Inbound channel |
| `port` | number | `3000` | Port for the HTTP API server |
| `host` | string | `"0.0.0.0"` | Bind address (`0.0.0.0` for all interfaces, `127.0.0.1` for localhost only) |
| `apiKeys` | object | `{}` | Map of API keys to their configurations |

### API Key Configuration

Each API key entry has the following structure:

```json
{
  "your-api-key-here": {
    "name": "Human-readable name",
    "created": "2026-03-09",
    "permissions": ["chat.send"]
  }
}
```

## API Usage

### Endpoint

```
POST http://your-openclaw-server:3000/api/chat
```

### Authentication

Include your API key in the `Authorization` header:

```
Authorization: Bearer your-api-key-here
```

### Request Body

```json
{
  "message": "Hello, OpenClaw!",
  "sessionId": "optional-session-id",
  "userId": "optional-user-id"
}
```

**Fields:**
- `message` (required): The user's message text
- `sessionId` (optional): Custom session ID for conversation continuity. If not provided, one will be generated.
- `userId` (optional): User identifier for tracking. If not provided, "anonymous" is used.

### Response

**Success (200 OK):**
```json
{
  "ok": true,
  "reply": "AI response text here",
  "sessionId": "http-inbound:user-123"
}
```

**Error (4xx/5xx):**
```json
{
  "ok": false,
  "error": "Error message here"
}
```

### Health Check

```
GET http://your-openclaw-server:3000/health
```

No authentication required. Returns:
```json
{
  "ok": true,
  "status": "running"
}
```

## Example Usage

### cURL

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Authorization: Bearer agentdigitaltwin-key-abc123" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is the weather today?",
    "userId": "user-123"
  }'
```

### Python

```python
import requests

url = "http://your-server:3000/api/chat"
headers = {
    "Authorization": "Bearer agentdigitaltwin-key-abc123",
    "Content-Type": "application/json"
}
data = {
    "message": "Hello, OpenClaw!",
    "userId": "user-123"
}

response = requests.post(url, json=data, headers=headers)
result = response.json()

if result["ok"]:
    print(f"AI Reply: {result['reply']}")
else:
    print(f"Error: {result['error']}")
```

### JavaScript/TypeScript

```typescript
const response = await fetch("http://your-server:3000/api/chat", {
  method: "POST",
  headers: {
    "Authorization": "Bearer agentdigitaltwin-key-abc123",
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    message: "Hello, OpenClaw!",
    userId: "user-123"
  })
});

const result = await response.json();

if (result.ok) {
  console.log("AI Reply:", result.reply);
} else {
  console.error("Error:", result.error);
}
```

## Security Best Practices

1. **Use HTTPS in production** - Deploy behind a reverse proxy (nginx, Caddy) with SSL/TLS
2. **Restrict bind address** - Use `"host": "127.0.0.1"` if accessing only via reverse proxy
3. **Rotate API keys** - Regularly generate new keys and revoke old ones
4. **Monitor usage** - Check OpenClaw logs for suspicious activity
5. **Firewall rules** - Restrict access to the API port to trusted IP addresses

## Generating API Keys

API keys can be any secure random string. You can generate them using:

```bash
# Using OpenSSL
openssl rand -hex 32

# Using Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# Using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Then add the generated key to your `openclaw.json` config.

### Troubleshooting

### Plugin not loading

```bash
# Check plugin status
openclaw plugins list

# Check logs
openclaw gateway --verbose
```

### Port already in use

Change the `port` in your config to an available port (e.g., 3001, 8080).

### API key not working

- Verify the key is correctly added to `channels.http-inbound.apiKeys` in config
- Restart the OpenClaw gateway after config changes
- Check the `Authorization` header format: `Bearer <key>`

### No response from AI

- Check OpenClaw gateway logs for errors
- Verify your agent/model configuration is correct
- Ensure the gateway is running: `openclaw gateway status`

## Development

### Build

```bash
npm install
npm run build
```

### Watch mode (auto-rebuild on changes)

```bash
npm run dev
```

### Testing locally

1. Build the plugin
2. Install to OpenClaw
3. Configure and restart gateway
4. Test with curl or your application

## License

MIT

## Contributing

Contributions welcome! Please open an issue or pull request.

## Support

For issues and questions:
- OpenClaw Discord: https://discord.gg/clawd
- GitHub Issues: https://github.com/your-username/openclaw-plugin-http-inbound/issues
