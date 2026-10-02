# Story conventions

- Import production components and keep the existing typed CSF3 story format.
- Describe each state once with deterministic args. Keep shared domain fixtures and connected-dependency mocks separate
  from production components.
- Put component interactions and user-visible assertions in `play`, using roles, accessible names, labels, or visible
  text. Keep non-DOM logic in unit tests and full backend flows in Playwright E2E.
- Stories use the real application CSS and light/dark themes. Preserve interactive animations and scrolling; use the
  native screenshot pipeline to stabilize captures.
- Mock network dependencies and use bundled images and fonts. Stories must render without provider credentials or a
  running Phoenix server.
- Each tested story runs at desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`) in both themes. The
  screenshot follows rendering and `play` assertions.
- The screenshot setup follows Next Station Paris: sequential story files, reduced motion, pinned Chromium, and DejaVu
  fallback fonts. Comparisons allow up to 30 mismatched pixels. Storybook bundles DM Sans separately.
- References belong under `assets/__screenshots__/<story-path>/<theme>/<viewport>/chromium/`. Generate intentional
  changes with `just assets test:visual --update`, inspect the images and Git diff, then run a normal comparison. CI
  never updates references.
- Keep generated actual images, diffs, reports, and traces out of version control. Use a filtered single-instance run
  when diagnosing failures.
- Generate the HTML report with `just assets test:visual --reporter=html`. Serve it with
  `just assets vite preview --outDir .vitest/report --port 4173` to inspect results and screenshot attachments.
- Capture traces with `just assets vitest run --project visual-light-mobile --browser.trace on`. Routine runs keep
  tracing disabled because shared instances cannot finalize concurrent trace chunks.
