import { userSchema } from "~contracts";
import { users } from "~fixtures/users";
import { describe, expect, test } from "vitest";

describe("users fixtures", () => {
  test("keep schema-valid users with non-empty avatar urls", () => {
    for (const user of Object.values(users)) {
      expect(userSchema.parse(user)).toEqual(user);
      expect(user.avatar_url).toMatch(
        /^https:\/\/api\.dicebear\.com\/9\.x\/thumbs\/svg\?seed=/,
      );
    }
  });
});
