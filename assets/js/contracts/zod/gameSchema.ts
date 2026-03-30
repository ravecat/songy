/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const game = z
  .object({
    id: z.string(),
    owner_id: z.string(),
    max_participants: z.number().int().gte(1),
    max_score: z.number().int().gte(1),
    status: z.enum(["waiting", "in_progress", "finished"]),
    participants: z
      .record(
        z.string(),
        z
          .object({
            uuid: z.string(),
            name: z.string(),
            avatar_url: z.string(),
          })
          .strict()
          .describe("JSON-encoded `Songy.Core.User`"),
      )
      .describe("Connected and known room participants keyed by user id"),
    scores: z
      .record(z.string(), z.number().int())
      .describe("Per-user scores keyed by user id"),
    player: z.union([
      z
        .object({ is_playback: z.boolean() })
        .strict()
        .describe("JSON-encoded `Songy.Core.Player`"),
      z.null(),
    ]),
    timelines: z
      .record(
        z.string(),
        z.array(
          z
            .object({
              id: z.string(),
              title: z.string(),
              artist: z.string(),
              year: z.number().int(),
              cover_url: z.union([z.string(), z.null()]),
              meta: z
                .object({
                  preview_url: z.string().optional(),
                  uri: z.string().optional(),
                })
                .catchall(z.unknown()),
            })
            .strict()
            .describe("JSON-encoded `Songy.Core.Track`"),
        ),
      )
      .describe("Per-user ordered timelines keyed by user id"),
    created_at: z.string().datetime({ offset: true }),
    queue: z.array(z.string()),
    cursor: z.number().int().gte(0),
    track: z.union([
      z
        .object({
          id: z.string(),
          title: z.string(),
          artist: z.string(),
          year: z.number().int(),
          cover_url: z.union([z.string(), z.null()]),
          meta: z
            .object({
              preview_url: z.string().optional(),
              uri: z.string().optional(),
            })
            .catchall(z.unknown()),
        })
        .strict()
        .describe("JSON-encoded `Songy.Core.Track`"),
      z.null(),
    ]),
    turn: z.union([
      z
        .object({
          phase: z.enum(["waiting", "ready", "challenging", "results"]),
          assumptions: z
            .record(z.string(), z.string())
            .describe(
              "Map keyed by JSON stringified zero-based positions. Values are user ids.\n",
            ),
          winner_id: z.union([z.string(), z.null()]),
          deadline_at_ms: z
            .union([z.number().int().gte(0), z.null()])
            .describe(
              "Authoritative challenging-phase deadline as Unix epoch time in milliseconds. Null outside time-bound phases.\n",
            ),
        })
        .strict()
        .describe("JSON-encoded `Songy.Core.Turn`"),
      z.null(),
    ]),
  })
  .strict()
  .describe("JSON-encoded `Songy.Core.Game` snapshot");
