import { ws } from "msw";
import { setupWorker } from "msw/browser";

const protocol = window.location.protocol === "https:" ? "wss" : "ws";

const socket = ws.link(`${protocol}://${window.location.host}/socket/websocket`);

export const worker = setupWorker(
  socket.addEventListener("connection", ({ client }) => {
    console.log("[msw] intercepted Phoenix WebSocket connection:", client.url);

    client.addEventListener("message", (event) => {
      console.log("[msw] Phoenix client message:", event.data);
    });

    client.addEventListener("close", (event) => {
      console.log("[msw] Phoenix client disconnected:", {
        code: event.code,
        reason: event.reason,
        wasClean: event.wasClean,
      });
    });
  }),
);
