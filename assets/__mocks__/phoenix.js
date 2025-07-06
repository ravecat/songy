import { vi } from "vitest";

export const Push = vi.fn(function (channel, event, payload, timeout) {
  this.channel = channel;
  this.event = event;
  this.payload = payload;
  this.timeout = timeout;
  this.send = vi.fn();
  this.resend = vi.fn();
  this.receive = vi.fn().mockReturnThis();
});

export const Channel = vi.fn(function (topic, params, socket) {
  this.topic = topic;
  this.params = params;
  this.socket = socket;
  this.state = "closed";
  this.join = vi.fn(() => new Push(this, "phx_join", {}, 10000));
  this.leave = vi.fn(() => new Push(this, "phx_leave", {}, 10000));
  this.push = vi.fn(
    (event, payload, timeout = 10000) => new Push(this, event, payload, timeout)
  );
  this.on = vi.fn();
  this.off = vi.fn();
  this.onClose = vi.fn();
  this.onError = vi.fn();
  this.onMessage = vi.fn();
});

export const Socket = vi.fn(function (endpoint, options) {
  this.endpoint = endpoint;
  this.options = options;
  this.connect = vi.fn();
  this.channel = vi.fn((topic, params) => new Channel(topic, params, this));
  this.disconnect = vi.fn();
  this.isConnected = vi.fn(() => true);
  this.connectionState = vi.fn(() => "open");
  this.remove = vi.fn();
  this.push = vi.fn();
  this.onOpen = vi.fn();
  this.onClose = vi.fn();
  this.onError = vi.fn();
  this.onMessage = vi.fn();
});
