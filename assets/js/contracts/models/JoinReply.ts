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
        reason: "game_not_found";
      };
    };
