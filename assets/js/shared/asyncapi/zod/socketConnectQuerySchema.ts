/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const socketConnectQuery = z
  .object({
    vsn: z.literal("2.0.0").describe("Phoenix serializer version"),
    user_token: z
      .string()
      .describe(
        "Short-lived token signed with `Phoenix.Token` on page load. Used by `UserSocket.connect/3` to authenticate the connection. Max age is 24 hours.\n",
      ),
  })
  .strict()
  .describe("Query parameters for WebSocket connect");
