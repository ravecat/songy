
import type { Game, Permissions, User } from "~contracts";

const avatar = (label: string, color: string) =>
  `data:image/svg+xml;utf8,${encodeURIComponent(`
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96">
      <rect width="96" height="96" rx="24" fill="${color}" />
      <text
        x="48"
        y="56"
        fill="white"
        font-size="34"
        font-family="Arial, sans-serif"
        font-weight="700"
        text-anchor="middle"
      >
        ${label}
      </text>
    </svg>
  `)}`;

export const users = {
  alice: {
    uuid: "user-1",
    name: "Alice",
    avatar_url: avatar("A", "#d97706"),
  },
  bob: {
    uuid: "user-2",
    name: "Bob",
    avatar_url: avatar("B", "#2563eb"),
  },
  carol: {
    uuid: "user-3",
    name: "Carol",
    avatar_url: avatar("C", "#7c3aed"),
  },
} satisfies Record<string, User>;

export const game = {
  id: "storybook-room",
  owner_id: users.alice.uuid,
  max_participants: 8,
  max_score: 10,
  status: "waiting",
  participants: {
    [users.alice.uuid]: users.alice,
    [users.bob.uuid]: users.bob,
    [users.carol.uuid]: users.carol,
  },
  scores: {
    [users.alice.uuid]: 7,
    [users.bob.uuid]: 4,
    [users.carol.uuid]: 6,
  },
  player: {
    is_playback: false,
  },
  timelines: {
    [users.alice.uuid]: [],
    [users.bob.uuid]: [],
    [users.carol.uuid]: [],
  },
  created_at: "2026-03-23T12:00:00.000Z",
  queue: [users.alice.uuid, users.bob.uuid, users.carol.uuid],
  cursor: 0,
  track: null,
  turn: null,
} satisfies Game;

export const permissions = {
  can_control_playback: false,
  can_advance_turn: false,
  can_start_game: false,
  can_start_turn: false,
  can_restart_game: false,
  can_see_assumptions: false,
  can_make_assumptions: false,
} satisfies Permissions;
