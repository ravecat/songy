export const phxJoin = {
  game: {
    owner_id: "user-1",
    participants: {
      "user-1": {
        uuid: "user-1",
        name: "Alice",
        avatar_url: "https://example.com/alice.jpg",
      },
    },
    queue: ["user-1"],
    cursor: 0,
    status: "waiting",
    turn: null,
    player: {
      is_playback: false,
    },
    scores: {},
  },
  permissions: {
    can_control_playback: false,
    can_advance_turn: false,
    can_start_game: true,
    can_start_turn: false,
    can_restart_game: false,
    can_see_assumptions: false,
    can_make_assumptions: false,
  },
  timer: null,
};
