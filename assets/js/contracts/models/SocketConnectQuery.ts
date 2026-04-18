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
   * Signed user token issued on page render and accepted during socket authentication with a maximum age of 86400 seconds
   *
   */
  user_token: string;
}
