/**
 * Permissions module - unified re-export from authorization.ts
 *
 * The permission logic is now centralized using Casbin, which provides
 * unified authorization across both frontend (TypeScript) and backend (Elixir).
 *
 * @see authorization.ts for implementation details
 */

export {
  computeGamePermissions,
  initCasbin,
  type GamePermissions,
  type PermissionContext,
} from './authorization';
