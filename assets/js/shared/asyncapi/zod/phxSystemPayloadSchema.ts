/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const phxSystemPayload = z
  .record(z.string(), z.unknown())
  .describe("Phoenix protocol payload for channel lifecycle events");
