/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const emptyPayload = z
  .record(z.string(), z.never())
  .describe("Event without application payload fields");
