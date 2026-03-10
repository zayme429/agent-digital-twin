import type { ChannelPlugin } from "openclaw/plugin-sdk";
import express, { Request, Response, NextFunction } from "express";
import { v4 as uuidv4 } from "uuid";

// Store the runtime API from register()
let runtimeChannelAPI: any = null;

// Function to set the runtime API (called from index.ts)
export function setRuntimeAPI(api: any) {
  runtimeChannelAPI = api;
}

interface ResolvedAccount {
  enabled: boolean;
  port: number;
  host: string;
  apiKeys: Record<string, ApiKeyConfig>;
}

interface ApiKeyConfig {
  name: string;
  created: string;
  permissions?: string[];
}

interface ChatRequest {
  message: string;
  sessionId?: string;
  userId?: string;
}

interface ChatResponse {
  ok: boolean;
  reply?: string;
  sessionId?: string;
  error?: string;
}

// Global server instance to prevent multiple bindings
// Note: We don't use this anymore, instead we store in ctx
let globalHttpServer: any = null;

// Global context reference (set during startAccount)
let globalContext: any = null;

// Middleware to verify API key
function verifyApiKey(apiKeys: Record<string, ApiKeyConfig>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      res.status(401).json({ ok: false, error: "Missing or invalid Authorization header" });
      return;
    }

    const token = authHeader.substring(7);

    if (!apiKeys[token]) {
      res.status(403).json({ ok: false, error: "Invalid API key" });
      return;
    }

    // Attach API key info to request
    (req as any).apiKey = token;
    (req as any).apiKeyConfig = apiKeys[token];
    next();
  };
}

export const httpInboundPlugin: ChannelPlugin<ResolvedAccount> = {
  id: "http-inbound",

  meta: {
    id: "http-inbound",
    label: "HTTP Inbound API",
    selectionLabel: "HTTP Inbound API",
    docsPath: "/channels/http-inbound",
    blurb: "Connect custom applications via HTTP REST API"
  },

  capabilities: {
    chatTypes: ["direct"],
    media: false,
    reactions: false,
    threads: false,
    polls: false
  },

  config: {
    listAccountIds: (cfg: any) => {
      console.log("[http-inbound] listAccountIds called, cfg:", JSON.stringify(cfg));
      return ["default"];
    },

    resolveAccount: (cfg: any, accountId: any) => {
      console.log("[http-inbound] resolveAccount called, accountId:", accountId);
      // cfg is the channel-specific config from channels.http-inbound
      // If cfg.channels exists, we need to extract the http-inbound config
      const channelCfg = cfg.channels && cfg.channels['http-inbound'] ? cfg.channels['http-inbound'] : cfg;
      console.log("[http-inbound] channelCfg:", JSON.stringify(channelCfg));
      const account = {
        enabled: channelCfg.enabled !== false,
        port: channelCfg.port || 3000,
        host: channelCfg.host || "0.0.0.0",
        apiKeys: channelCfg.apiKeys || {}
      };
      console.log("[http-inbound] resolved account:", JSON.stringify(account));
      return account;
    },

    isConfigured: (account: any) => {
      const configured = Object.keys(account.apiKeys).length > 0;
      console.log("[http-inbound] isConfigured called, apiKeys count:", Object.keys(account.apiKeys).length, "result:", configured);
      return configured;
    },

    isEnabled: (account: any) => {
      const enabled = account.enabled !== false;
      console.log("[http-inbound] isEnabled called, account.enabled:", account.enabled, "result:", enabled);
      return enabled;
    }
  },

  gateway: {
    startAccount: async (ctx: any) => {
      console.log("[http-inbound] startAccount called!");

      // Store context globally for use in HTTP handlers
      globalContext = ctx;
      console.log("[http-inbound] globalContext stored");

      const { account } = ctx;
      console.log("[http-inbound] account:", JSON.stringify(account, null, 2));

      // Check if server is already running in this context
      if ((ctx as any).httpServer?.listening) {
        console.log("[http-inbound] HTTP server already running in context, skipping start");
        return;
      }

      console.log("[http-inbound] Creating new HTTP server");

      const app = express();

      app.use(express.json());

      // Health check endpoint (no auth required)
      app.get("/health", (req, res) => {
        res.json({ ok: true, status: "running" });
      });

      // Chat endpoint (requires API key)
      app.post("/api/chat", verifyApiKey(account.apiKeys), async (req, res) => {
        try {
          const { message, sessionId, userId }: ChatRequest = req.body;

          if (!message || typeof message !== "string") {
            res.status(400).json({ ok: false, error: "Missing or invalid 'message' field" });
            return;
          }

          // Generate session ID if not provided
          const finalSessionId = sessionId || `http-inbound:${userId || uuidv4()}`;
          const senderId = userId || "anonymous";

          console.log("[http-inbound] Processing chat request:", { message, userId: senderId, sessionId: finalSessionId });

          // Use the stored global context
          if (!globalContext) {
            console.error("[http-inbound] globalContext not available");
            res.status(500).json({
              ok: false,
              error: "Channel context not initialized"
            });
            return;
          }

          console.log("[http-inbound] globalContext keys:", Object.keys(globalContext));

          // Check if runtime channel API is available
          if (!runtimeChannelAPI) {
            console.error("[http-inbound] Runtime channel API not available");
            res.status(500).json({
              ok: false,
              error: "Runtime channel API not available"
            });
            return;
          }

          // Resolve agent route
          const route = runtimeChannelAPI.routing?.resolveAgentRoute?.({
            cfg: globalContext.cfg,
            channel: "http-inbound",
            accountId: "default",
            peer: { kind: "dm", id: finalSessionId }
          }) || { sessionKey: finalSessionId, agentId: "default", accountId: "default" };

          console.log("[http-inbound] Resolved route:", route);

          // Build context payload
          const from = `http-inbound:user:${senderId}`;
          const to = `user:${senderId}`;

          const ctxPayload = {
            Body: message,
            RawBody: message,
            CommandBody: message,
            From: from,
            To: to,
            SessionKey: route.sessionKey,
            AccountId: route.accountId,
            ChatType: "direct",
            ConversationLabel: `user:${senderId}`,
            SenderName: senderId,
            SenderId: senderId,
            Provider: "http-inbound",
            Surface: "http-inbound",
            OriginatingChannel: "http-inbound",
            OriginatingTo: to,
            CommandAuthorized: true
          };

          let replyText = "";

          // Dispatch to AI agent
          await runtimeChannelAPI.reply.dispatchReplyWithBufferedBlockDispatcher({
            ctx: ctxPayload,
            cfg: globalContext.cfg,
            dispatcherOptions: {
              deliver: async (payload: any) => {
                const text = payload.text ?? "";
                if (text.trim()) {
                  replyText += text;
                }
              },
              onError: (err: any, info: any) => {
                console.error(`[http-inbound] ${info.kind} reply failed:`, err);
              }
            }
          });

          const response: ChatResponse = {
            ok: true,
            reply: replyText || "No response from agent",
            sessionId: finalSessionId
          };

          res.json(response);
        } catch (error: any) {
          console.error("[http-inbound] Error processing chat request:", error);
          res.status(500).json({
            ok: false,
            error: error.message || "Internal server error"
          });
        }
      });

      // Start HTTP server
      try {
        const server = app.listen(account.port, account.host, () => {
          console.log(`[http-inbound] HTTP API server listening on ${account.host}:${account.port}`);
          console.log(`[http-inbound] Active API keys: ${Object.keys(account.apiKeys).length}`);
        });

        // Handle server errors
        server.on('error', (err: any) => {
          if (err.code === 'EADDRINUSE') {
            console.log(`[http-inbound] Port ${account.port} already in use, server may already be running`);
          } else {
            console.error('[http-inbound] Server error:', err);
          }
        });

        // Store server instance in context (not global)
        (ctx as any).httpServer = server;
      } catch (err) {
        console.error('[http-inbound] Failed to start server:', err);
        // Don't throw - let OpenClaw handle the retry
      }
    },

    stopAccount: async (ctx: any) => {
      const server = (ctx as any).httpServer;
      if (server) {
        await new Promise<void>((resolve) => {
          server.close(() => {
            console.log("[http-inbound] HTTP API server stopped");
            resolve();
          });
        });
      }
    }
  },

  outbound: {
    deliveryMode: "direct",

    sendPayload: async (ctx: any) => {
      // HTTP Inbound is a one-way channel (inbound only)
      // Replies are sent synchronously in the HTTP response
      // This method is required by the interface but not used
      return {
        ok: true,
        channel: "http-inbound",
        messageId: ctx.payload?.messageId || "unknown"
      };
    }
  }
};
