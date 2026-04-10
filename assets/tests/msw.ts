import { ws } from "msw";
import { setupWorker } from "msw/browser";

import { handlers } from "./handlers";
import { parseFrame } from "./phoenix";

const socket = ws.link(`//${window.location.host}/socket/websocket`);

export const socketHandlers = [
  socket.addEventListener("connection", ({ client }) => {
    client.addEventListener("message", (event) => {
      const frame = parseFrame(event.data);
      const [, , topic, eventName] = frame;
      const handler = handlers[topic]?.[eventName];

      console.log("[MSW] WS frame", { topic, eventName, frame });

      if (handler) {
        handler(client, frame);
        return;
      }

      console.warn("[MSW] Unhandled WS frame", frame);
    });
  }),
];

export const worker = setupWorker(...socketHandlers);
