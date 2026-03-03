/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

export type JoinReply =
  | {
      status: "ok";
      response: {
        [k: string]: unknown;
      };
    }
  | {
      status: "error";
      response: {
        /**
         * Error reason (e.g. "game_not_found")
         */
        reason: string;
      };
    };
