/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const receiveErrorPayloadSchema = z
  .record(z.string(), z.unknown())
  .describe("Phoenix protocol payload for lifecycle events");
