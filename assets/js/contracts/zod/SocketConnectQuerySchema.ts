/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const socketConnectQuerySchema = z
  .object({
    vsn: z
      .literal("2.0.0")
      .describe("Phoenix serializer version added by the Phoenix client"),
    user_token: z
      .string()
      .describe(
        "Signed user token issued on page render and accepted during socket authentication with a maximum age of 86400 seconds\n",
      ),
  })
  .strict()
  .describe(
    "Query parameters used by the Phoenix JS client during socket connect",
  );
