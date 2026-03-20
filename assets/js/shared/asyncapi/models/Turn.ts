/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * JSON-encoded `Songy.Core.Turn`
 */
export interface Turn {
  phase: "waiting" | "ready" | "challenging" | "results";
  /**
   * Map keyed by JSON stringified zero-based positions. Values are user ids.
   *
   */
  assumptions: {
    [k: string]: string;
  };
  winner_id: string | null;
}
