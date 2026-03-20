/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const invalidCredentialsReply = z
  .object({
    status: z.literal("error"),
    response: z.object({ reason: z.literal("invalid_credentials") }).strict(),
  })
  .strict();
