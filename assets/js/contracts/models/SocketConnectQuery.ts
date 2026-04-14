/**
 * Generated from AsyncAPI spec.
 * Do not edit manually.
 */

/**
 * Query parameters used by the Phoenix JS client during socket connect
 */
export interface SocketConnectQuery {
  /**
   * Phoenix serializer version added by the Phoenix client
   */
  vsn: "2.0.0";
  /**
   * `Phoenix.Token` signed on page render and verified by `SongyWeb.UserSocket.connect/3` with `max_age: 86400`
   *
   */
  user_token: string;
}
