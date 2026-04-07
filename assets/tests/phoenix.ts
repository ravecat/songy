import * as Phoenix from "phoenix";

interface Envelope<
  TPayload = unknown,
  TEvent extends string = string,
> {
  join_ref: PhoenixFrame<TPayload, TEvent>[0];
  ref: PhoenixFrame<TPayload, TEvent>[1];
  topic: PhoenixFrame<TPayload, TEvent>[2];
  event: TEvent;
  payload: TPayload;
}

interface Serializer {
  decode(
    payload: string | ArrayBuffer,
    callback: (
      decoded: Envelope,
    ) => void,
  ): void;
  encode(
    message: Envelope,
    callback: (
      encoded: string | ArrayBuffer,
    ) => void,
  ): void;
}

const serializer = (Phoenix as unknown as { Serializer: Serializer })
  .Serializer;

export function parseFrame(data: unknown): PhoenixFrame {
  let frame!: PhoenixFrame;

  serializer.decode(data as string | ArrayBuffer, (decoded) => {
    frame = [
      decoded.join_ref,
      decoded.ref,
      decoded.topic,
      decoded.event,
      decoded.payload,
    ];
  });

  return frame;
}

export function replyTo(
  [join_ref, ref, topic]: PhoenixFrame,
  reply: {
    status: PhoenixReplyStatus;
    response: unknown;
  },
) {
  let encoded!: string | ArrayBuffer;

  serializer.encode(
    {
      join_ref,
      ref,
      topic,
      event: "phx_reply",
      payload: reply,
    },
    (next) => {
      encoded = next;
    },
  );

  return encoded;
}
