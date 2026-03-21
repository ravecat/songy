/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const joinPayload = z
  .record(z.string(), z.unknown())
  .describe("Join payload accepted by the room channel");
