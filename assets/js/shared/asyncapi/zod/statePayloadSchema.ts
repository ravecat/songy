/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

import { z } from "zod/v4";

export const statePayload = z
  .object({
    game: z
      .object({
        id: z
          .string()
          .describe("Room ID (unique_names_generator slug)")
          .optional(),
        state: z
          .enum([
            "lobby",
            "playing",
            "turn",
            "challenging",
            "scoring",
            "finished",
          ])
          .describe("Current FSM state")
          .optional(),
        host_id: z.string().describe("User ID of the room creator").optional(),
        players: z
          .array(
            z
              .object({
                id: z.string().optional(),
                name: z.string().optional(),
                score: z.number().int().optional(),
              })
              .catchall(z.unknown())
              .describe("Player state within the game"),
          )
          .optional(),
        turn: z
          .union([
            z
              .object({
                track: z
                  .object({
                    id: z.string().optional(),
                    name: z.string().optional(),
                    artist: z.string().optional(),
                    uri: z
                      .string()
                      .describe("Provider URI (e.g. Spotify track URI)")
                      .optional(),
                  })
                  .catchall(z.unknown())
                  .describe("Music track data")
                  .optional(),
                assumptions: z
                  .record(z.string(), z.number().int())
                  .describe("Map of user_id to guessed position")
                  .optional(),
              })
              .catchall(z.unknown())
              .describe("Current turn state"),
            z.null(),
          ])
          .optional(),
        tracks: z
          .array(
            z
              .object({
                id: z.string().optional(),
                name: z.string().optional(),
                artist: z.string().optional(),
                uri: z
                  .string()
                  .describe("Provider URI (e.g. Spotify track URI)")
                  .optional(),
              })
              .catchall(z.unknown())
              .describe("Music track data"),
          )
          .optional(),
      })
      .catchall(z.unknown())
      .describe(
        "Game struct serialized from `Songy.Core.Game`. All fields are\nJason-encoded. The `state` field is the GenStatem FSM state name.\n",
      ),
    permissions: z
      .object({
        can_start_game: z.boolean().optional(),
        can_start_playback: z.boolean().optional(),
        can_pause_playback: z.boolean().optional(),
        can_advance_turn: z.boolean().optional(),
        can_make_assumption: z.boolean().optional(),
      })
      .catchall(z.unknown())
      .describe(
        "Caller-specific permission flags computed by `Songy.Authorization`.\nAll boolean fields; missing key means `false`.\n",
      ),
  })
  .describe("Full game state and caller's permissions");
