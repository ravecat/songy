/**
 * Generated from AsyncAPI spec (asyncapi.yaml).
 * Do not edit manually.
 */

/**
 * Query parameters for WebSocket connect
 */
export interface SocketConnectQuery {
  /**
   * Phoenix serializer version
   */
  vsn: "2.0.0";
  /**
   * Short-lived token signed with `Phoenix.Token` on page load. Used by `UserSocket.connect/3` to authenticate the connection. Max age is 24 hours.
   *
   */
  user_token: string;
}
