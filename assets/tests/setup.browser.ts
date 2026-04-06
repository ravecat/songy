import { afterAll, afterEach, beforeAll } from "vitest";
import { worker } from "./msw";

let workerStart: Promise<unknown> | null = null;

beforeAll(() => {
  window.userToken = "vitest-browser-user-token";

  workerStart ??= worker.start({
    onUnhandledRequest: "bypass",
    quiet: true,
  });

  return workerStart;
});

afterEach(() => {
  worker.resetHandlers();
});

afterAll(() => {
  worker.stop();
  workerStart = null;
});
