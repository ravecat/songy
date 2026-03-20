/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const socketConnectQuery = z
  .object({
    vsn: z
      .literal("2.0.0")
      .describe("Phoenix serializer version added by the Phoenix client"),
    user_token: z
      .string()
      .describe(
        "`Phoenix.Token` signed on page render and verified by `SongyWeb.UserSocket.connect/3` with `max_age: 86400`\n",
      ),
  })
  .strict()
  .describe(
    "Query parameters used by the Phoenix JS client during socket connect",
  );
