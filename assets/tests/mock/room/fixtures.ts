import type { User } from "~contracts";

export const users = {
  alice: {
    uuid: "user-1",
    name: "Alice",
    avatar_url: "https://example.com/alice.jpg",
  },
  bob: {
    uuid: "user-2",
    name: "Bob",
    avatar_url: "https://example.com/bob.jpg",
  },
  carol: {
    uuid: "user-3",
    name: "Carol",
    avatar_url: "https://example.com/carol.jpg",
  },
} satisfies Record<string, User>;

export const tracks = {
  current: {
    id: "track-current",
    title: "Current Track",
    artist: "Current Artist",
    year: 2024,
    cover_url: "https://example.com/current-cover.jpg",
    meta: {
      preview_url: "https://example.com/current-preview.mp3",
    },
  },
  timelineOne: {
    id: "timeline-1",
    title: "Timeline Track 1",
    artist: "Artist 1",
    year: 2020,
    cover_url: null,
    meta: {},
  },
  timelineTwo: {
    id: "timeline-2",
    title: "Timeline Track 2",
    artist: "Artist 2",
    year: 2021,
    cover_url: null,
    meta: {},
  },
  result: {
    id: "track-result",
    title: "Bohemian Rhapsody",
    artist: "Queen",
    year: 1975,
    cover_url: "https://example.com/cover.jpg",
    meta: {
      preview_url: "https://example.com/preview.mp3",
    },
  },
  media: {
    id: "1440783454",
    title: "Firestarter",
    artist: "The Prodigy",
    year: 1996,
    cover_url: null,
    meta: {
      preview_url: "https://audio-ssl.itunes.apple.com/preview.m4a",
    },
  },
};

export const basePermissions = {
  can_control_playback: false,
  can_advance_turn: false,
  can_start_game: false,
  can_start_turn: false,
  can_restart_game: false,
  can_see_assumptions: false,
  can_make_assumptions: false,
};

export const roomSnapshot = {
  game: {
    id: "room-1",
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
      [users.alice.uuid]: [tracks.timelineOne, tracks.timelineTwo],
      [users.bob.uuid]: [tracks.timelineOne, tracks.timelineTwo],
      [users.carol.uuid]: [],
    },
    created_at: "2026-03-23T12:00:00.000Z",
    queue: [users.alice.uuid, users.bob.uuid, users.carol.uuid],
    cursor: 0,
    track: null,
    turn: null,
  },
  permissions: basePermissions,
  timer: null,
};
