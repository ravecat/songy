/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const joinPayloadSchema = z
  .record(z.string(), z.unknown())
  .describe("Join payload accepted by the room channel");
