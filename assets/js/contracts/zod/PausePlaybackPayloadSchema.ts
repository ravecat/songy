/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const pausePlaybackPayloadSchema = z
  .record(z.string(), z.never())
  .describe("Event without application payload fields");
