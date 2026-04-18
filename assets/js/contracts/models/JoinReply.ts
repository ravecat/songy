/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

export type JoinReply =
  | {
      status: "ok";
      /**
       * Authoritative room snapshot sent to the client
       */
      response: {
        /**
         * JSON-encoded game snapshot
         */
        game: {
          id: string;
          owner_id: string;
          max_participants: number;
          max_score: number;
          status: "waiting" | "in_progress" | "finished";
          /**
           * Connected and known room participants keyed by user id
           */
          participants: {
            /**
             * JSON-encoded user
             */
            [k: string]: {
              id: string;
              name: string;
              avatar_url: string;
            };
          };
          /**
           * Per-user scores keyed by user id
           */
          scores: {
            [k: string]: number;
          };
          player: {
            is_playback: boolean;
          } | null;
          /**
           * Per-user ordered timelines keyed by user id
           */
          timelines: {
            [k: string]: {
              id: string;
              title: string;
              artist: string;
              year: number;
              cover_url: string | null;
              meta: {
                preview_url?: string;
                uri?: string;
                [k: string]: unknown;
              };
            }[];
          };
          created_at: string;
          queue: string[];
          cursor: number;
          track: {
            id: string;
            title: string;
            artist: string;
            year: number;
            cover_url: string | null;
            meta: {
              preview_url?: string;
              uri?: string;
              [k: string]: unknown;
            };
          } | null;
          turn: {
            phase: "waiting" | "ready" | "challenging" | "results";
            /**
             * Map keyed by JSON stringified zero-based positions. Values are user ids.
             *
             */
            assumptions: {
              [k: string]: string;
            };
            winner_id: string | null;
            /**
             * Authoritative challenging-phase deadline as Unix epoch time in milliseconds. Null outside time-bound phases.
             *
             */
            deadline_at_ms: number | null;
          } | null;
        };
        /**
         * Caller-specific permissions computed by the authorization layer
         */
        permissions: {
          can_control_playback: boolean;
          can_advance_turn: boolean;
          can_start_game: boolean;
          can_start_turn: boolean;
          can_restart_game: boolean;
          can_see_assumptions: boolean;
          can_make_assumptions: boolean;
        };
      };
    }
  | {
      status: "error";
      response: {
        reason: "game_not_found";
      };
    };
