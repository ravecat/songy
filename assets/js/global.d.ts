/**
 * Global window type extensions for Phoenix socket integration.
 * 
 * This file extends the global Window interface to include Phoenix-related tokens.
 * Import this file to make window.userToken available.
 */

export { };
declare global {
  interface Window {
    /** User authentication token for Phoenix socket */
    userToken?: string;
  }
}

