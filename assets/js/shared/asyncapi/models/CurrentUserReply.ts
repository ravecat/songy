/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

export interface CurrentUserReply {
  status: "ok";
  /**
   * JSON-encoded `Songy.Core.User`
   */
  response: {
    uuid: string;
    name: string;
    avatar_url: string;
  };
}
