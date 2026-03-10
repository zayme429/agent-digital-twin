import { httpInboundPlugin, setRuntimeAPI } from "./channel.js";

const plugin = {
  id: "http-inbound",
  name: "HTTP Inbound API",
  description: "HTTP Inbound channel for OpenClaw - allows custom apps to connect via REST API",
  register(api: any) {
    console.log("[http-inbound] register() called");

    // Store the runtime channel API for use in HTTP handlers
    if (api.runtime?.channel) {
      setRuntimeAPI(api.runtime.channel);
      console.log("[http-inbound] Runtime channel API stored");
    } else {
      console.error("[http-inbound] Runtime channel API not available in register()");
    }

    api.registerChannel({ plugin: httpInboundPlugin });
    console.log("[http-inbound] registerChannel() completed");
  }
};

export default plugin;


