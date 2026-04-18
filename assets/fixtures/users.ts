import { userSchema } from "~contracts";
import { zocker } from "zocker";

export const users = {
  alice: zocker(userSchema)
    .setSeed(1)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=alice")
    .generate(),
  bob: zocker(userSchema)
    .setSeed(2)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=bob")
    .generate(),
  carol: zocker(userSchema)
    .setSeed(3)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=carol")
    .generate(),
  dan: zocker(userSchema)
    .setSeed(4)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=dan")
    .generate(),
  erin: zocker(userSchema)
    .setSeed(5)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=erin")
    .generate(),
  frank: zocker(userSchema)
    .setSeed(6)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=frank")
    .generate(),
  gina: zocker(userSchema)
    .setSeed(7)
    .supply(userSchema.shape.avatar_url, "https://api.dicebear.com/9.x/thumbs/svg?seed=gina")
    .generate(),
};
