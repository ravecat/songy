/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const getProviderInvalidCredentialsReplyPayloadSchema = z
  .object({
    status: z.literal("error"),
    response: z.object({ reason: z.literal("invalid_credentials") }).strict(),
  })
  .strict();
