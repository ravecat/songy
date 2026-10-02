# Story conventions

- Import production components and keep the existing typed CSF3 story format.
- Describe each state once with deterministic args. Keep shared domain fixtures and connected-dependency mocks separate
  from production components.
- Put component interactions and user-visible assertions in `play`, using roles, accessible names, labels, or visible
  text. Keep non-DOM logic in unit tests and full backend flows in Playwright E2E.
- Stories use the real application CSS and light/dark themes. Preserve interactive animations and scrolling; use the
  native screenshot pipeline to stabilize captures.
- Mock network dependencies and use bundled images. Interactive Storybook loads DM Sans through Google Fonts; visual
  tests use local flake fonts without CDN requests. Stories must render without provider credentials or a running
  Phoenix server.
- Each tested story runs at desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`) in both themes. The
  screenshot follows rendering and `play` assertions.
- The screenshot setup follows d20: each theme/viewport instance reuses Chromium across parallel story files with two
  workers and sequential tests and hooks. Use reduced motion, pinned Chromium, and local DM Sans 1.002. Fontconfig maps
  DM Sans to its packaged DeepMind Sans name. Components inherit the application font and use weights 400, 600, and 700.
  Native pixelmatch permits a mismatched-pixel ratio of 0.001 (0.1%) with no absolute cap.
- Native screenshot styling freezes marquee text during capture. Interactive Storybook keeps normal animations.
- References belong under `assets/__screenshots__/<story-path>/<theme>/<viewport>/chromium/`. Generate intentional
  changes with `just assets test:visual --update`, inspect the images and Git diff, then run a normal comparison. CI
  never updates references.
- Keep generated actual images, diffs, failed-test screenshots, and reports out of version control. Use a filtered
  single-instance run when diagnosing failures.
- Generate the HTML report with `just assets test:visual --reporter=html`. Serve it with
  `just assets vite preview --outDir .vitest/report --port 4173` to inspect results and screenshot attachments. CI
  uploads only PNG failure attachments from `assets/.vitest/attachments/` for seven days. Automatic captures use
  separate theme and viewport directories without moving reviewed references.
- Vitest and Playwright tracing are disabled. CI does not upload traces, caches, HTML bundles, or the full baseline
  catalog.
