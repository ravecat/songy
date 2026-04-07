import { ws } from "msw";
import { setupWorker } from "msw/browser";

import {
  parseFrame,
  replyTo,
} from "./phoenix";
import { phxJoin } from "./mock/room/phx_join";

type Reply = {
  status: PhoenixReplyStatus;
  response: unknown;
};

const protocol = window.location.protocol === "https:" ? "wss" : "ws";

const socket = ws.link(
  `${protocol}://${window.location.host}/socket/websocket`,
);

const replies: Record<string, Record<string, Reply>> = {
  "room:room-1": {
    phx_join: { status: "ok", response: phxJoin },
    phx_leave: { status: "ok", response: {} },
  },
  "room:room-missing": {
    phx_join: {
      status: "error",
      response: { reason: "game_not_found" },
    },
    phx_leave: { status: "ok", response: {} },
  },
  phoenix: {
    heartbeat: { status: "ok", response: {} },
  },
};

export const worker = setupWorker(
  socket.addEventListener("connection", ({ client }) => {
    client.addEventListener("message", (event) => {
      const frame = parseFrame(event.data);
      const [, , topic, eventName] = frame;

      const reply = replies[topic]?.[eventName];

      if (reply) {
        client.send(replyTo(frame, reply));
        return;
      }

      if (topic in replies) {
        console.warn("[MSW] Unhandled Phoenix WS frame", frame);
        return;
      }

      console.warn("[MSW] Unhandled WS frame", frame);
    });
  })
);
