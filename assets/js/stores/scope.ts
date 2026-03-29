import { page } from "@inertiajs/svelte";
import { derived } from "svelte/store";

const scope = derived(page, ($page) => $page.props.scope);
export const currentUser = derived(scope, ($scope) => $scope.user);
export const provider = derived(
  scope,
  ($scope) => $scope.provider ?? undefined,
);
