/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const startGamePayloadSchema = z
  .record(z.string(), z.never())
  .describe("Event without application payload fields");
