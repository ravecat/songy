import { defineConfig } from "@rvct/asyncapi";
import { asyncapi } from "@rvct/asyncapi/plugins/asyncapi";
import { typescript } from "@rvct/asyncapi/plugins/typescript";
import { zod } from "@rvct/asyncapi/plugins/zod";

export default defineConfig({
  input: {
    path: "../priv/specs/asyncapi.yaml",
  },
  output: {
    path: "./js/contracts",
  },
  plugins: [
    asyncapi({
      output: {
        path: "schemas",
      },
    }),
    typescript({
      output: {
        path: "models",
      },
    }),
    zod({
      output: {
        path: "zod",
      },
    }),
  ],
});
