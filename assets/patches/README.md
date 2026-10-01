# Dependency patches

`@vitest/browser@4.1.4` leaves its screenshot stabilization timeout running after a successful comparison. The 15-second
timer exceeds Vitest's teardown budget and delays every visual run. The patch clears the timer in
`waitForStableScreenshot` on both success and failure while preserving the screenshot timeout and abort behavior.

Bun applies this patch during frozen installs. Remove it when the installed Vitest version fixes this cleanup in
[the screenshot matcher](https://github.com/vitest-dev/vitest/blob/v4.1.4/packages/browser/src/node/commands/screenshotMatcher/utils.ts).
