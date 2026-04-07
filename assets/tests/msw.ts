import { ws } from "msw";
import { setupWorker } from "msw/browser";

import {
  parseFrame,
  replyTo,
} from "./phoenix";
import { phxJoin } from "./mock/room/phx_join";

const protocol = window.location.protocol === "https:" ? "wss" : "ws";

export const socket = ws.link(
  `${protocol}://${window.location.host}/socket/websocket`,
);

export const worker = setupWorker(
  socket.addEventListener("connection", ({ client }) => {
    client.addEventListener("message", (event) => {
      const frame = parseFrame(event.data);
      const [, , topic, eventName] = frame;
      const route = `${topic}::${eventName}`;

      switch (route) {
        case "room:room-1::phx_join":
          client.send(replyTo(frame, { status: "ok", response: phxJoin }));
          return;

        case "phoenix::heartbeat":
          client.send(replyTo(frame, { status: "ok", response: {} }));
          return;

        case "room:room-1::phx_leave":
          client.send(replyTo(frame, { status: "ok", response: {} }));
          return;

        default:
          console.warn("[MSW] Unhandled Phoenix WS frame", frame);
          return;
      }
    });
  })
);
