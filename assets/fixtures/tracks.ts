import { trackSchema } from "~contracts";
import { zocker } from "zocker";

export const tracks = {
  current: zocker(trackSchema).setSeed(1).generate(),
  timelineOne: zocker(trackSchema).setSeed(2).generate(),
  timelineTwo: zocker(trackSchema).setSeed(3).generate(),
  result: zocker(trackSchema).setSeed(4).generate(),
};
