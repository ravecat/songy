import type { User } from "~contracts";
import "@inertiajs/core";

/**
 * Global window type extensions for Phoenix socket integration.
 *
 * This file extends the global Window interface to include Phoenix-related tokens.
 * Import this file to make window.userToken available.
 */

export { };

declare module "@inertiajs/core" {
  interface InertiaConfig {
    flashDataType: {
      info?: string;
      error?: string;
    };
    sharedPageProps: {
      scope: {
        user: User;
        provider: "itunes" | "spotify" | "apple" | null;
      };
    };
  }
}

declare global {
  interface Window {
    /** User authentication token for Phoenix socket */
    userToken?: string;
  }
}
