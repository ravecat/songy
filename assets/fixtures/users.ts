import { userSchema } from "~contracts";
import { zocker } from "zocker";

export const users = {
  alice: zocker(userSchema)
    .supply(
      userSchema.shape.avatar_url,
      "https://api.dicebear.com/9.x/thumbs/svg?seed=alice",
    )
    .generate(),
  bob: zocker(userSchema)
    .supply(
      userSchema.shape.avatar_url,
      "https://api.dicebear.com/9.x/thumbs/svg?seed=bob",
    )
    .generate(),
  carol: zocker(userSchema)
    .supply(
      userSchema.shape.avatar_url,
      "https://api.dicebear.com/9.x/thumbs/svg?seed=carol",
    )
    .generate(),
};
