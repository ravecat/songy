import { afterAll, afterEach } from "vitest";
import { worker } from "./msw";

window.userToken = "vitest-browser-user-token";

let workerStart: Promise<unknown> | null = worker.start({
  onUnhandledRequest: "bypass",
  quiet: true,
});

await workerStart;

afterEach(() => {
  worker.resetHandlers();
});

afterAll(() => {
  worker.stop();
  workerStart = null;
});
