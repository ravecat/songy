/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const emptyPayload = z
  .record(z.string(), z.unknown())
  .describe("No payload fields required");
