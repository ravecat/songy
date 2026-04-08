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
