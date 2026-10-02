# Songy

**[songy.ravecat.io](https://songy.ravecat.io/)**

## Requirements

- Nix (flakes enabled)
- direnv + nix-direnv (optional, for automatic environment activation)

## Setup

### 1. Install Nix

```bash
sh <(curl -L https://nixos.org/nix/install)
```

### 2. Enable flakes

```bash
mkdir -p ~/.config/nix
printf "experimental-features = nix-command flakes\n" >> ~/.config/nix/nix.conf
```

### 3. (Optional) Install direnv and nix-direnv

For automatic environment activation when entering the project directory:

```bash
# Install direnv
nix profile add nixpkgs#direnv

# Install nix-direnv
nix profile add nixpkgs#nix-direnv

# Configure nix-direnv hook
mkdir -p ~/.config/direnv
echo 'source $HOME/.nix-profile/share/nix-direnv/direnvrc' >> ~/.config/direnv/direnvrc

# Add direnv hook to shell (bash, for other shells see https://direnv.net/docs/hook.html)
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
```

### 4. Clone the repository

### 5. Start development

**With direnv (automatic):**

```bash
cd songy/
direnv allow
# Environment automatically activated
just setup
just up
```

If you need Storybook, run it in a separate terminal:

```bash
just storybook
```

**With manual Nix shell activation:**

```bash
cd songy/
nix develop
direnv allow
just setup
just up
```

If you need Storybook, run it in a separate terminal:

```bash
just storybook
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

The flake pins the same stable Nixpkgs revision as d20 (`nixos-26.05`) and provides Erlang/OTP 28, Elixir 1.20, Bun,
Node.js 24, Just, OpenSpec, watchexec, native compilation tools, and Prettier. `envs/.env` is loaded by direnv and the
application; copy `envs/.env.example` for local configuration. Songy keeps its state in memory and does not need
PostgreSQL.

`just setup` installs Hex, Rebar, Mix dependencies, and frontend dependencies using the Bun lockfile. `just up` also
runs setup and builds assets, then starts IEx/Phoenix and restarts it when environment files, configuration, or Mix
manifests change. Phoenix starts Vite with the Bun from the Nix shell. Storybook runs separately on port 6006.

Use the dispatchers to pass arguments directly to Mix or frontend tools:

```bash
just mix test
just mix test.watch
just assets test --watch
just assets test --coverage
just assets test --ui --watch
just assets test:unit
just assets test:browser
just assets test:visual
just assets check --watch
just assets typecheck
just assets e2e --reporter=list
just assets e2e --ui
just assets codegen
just assets build
```

`just format` formats Elixir and Markdown. `just check` validates OpenSpec, then runs backend formatting, compilation
and tests, Markdown formatting, Svelte/TypeScript checks, frontend tests with an HTML report, production compilation,
frontend/Storybook builds, and static asset digests. The flake provides Chromium matching the pinned Playwright
dependency. For a production release, run `MIX_ENV=prod mix compile`, `MIX_ENV=prod just assets deploy`, then
`MIX_ENV=prod mix phx.digest`; Docker runs these steps before building the release. The Docker builder retains d20's
release image with Elixir 1.19.5 and OTP 28.3.3 and installs Bun 1.3.13 separately.

## Storybook tests

Write component interactions and user-visible assertions in Storybook `play` functions. `just assets test` runs the unit
tests and Storybook tests through Vitest and the Chromium supplied by the flake. Storybook tests load the same
decorators, themes, fixtures, and request mocks as the interactive catalog; they do not need a running Phoenix server.
The old standalone component tests remain available through `just assets test:browser` while their behavior is moved
into stories.

```bash
nix develop
just assets test:visual
just assets test:visual --reporter=html
just assets vitest run --project 'visual-*-mobile'
just assets test:visual --update
just storybook
```

The screenshot setup follows d20. One visual project runs every discovered story in light and dark themes. The viewports
are desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`). Each theme/viewport instance reuses its Chromium
browser across parallel story files, with two workers and sequential tests and hooks. The test browser requests reduced
motion. Interactive Storybook keeps normal motion settings. Native screenshot styling freezes marquee text during
capture to keep font rendering stable.

Screenshots are captured after `play` with a 15-second native assertion timeout. Setup only resets the pointer and
compares the document; Playwright supplies font readiness without manual loading or image decoding. The environment uses
pinned Chromium and nixpkgs fonts: DM Sans 1.002 (named DeepMind Sans internally) and Source Code Pro for monospace and
fallback text. Fontconfig maps DM Sans to the local package. Interactive Storybook loads the current DM Sans through the
same Google Fonts request as production. Visual tests omit these links and use the local fonts from the flake without
CDN access. Native pixelmatch permits a mismatched-pixel ratio of 0.001 (0.1%) without an absolute allowance. References
live under `assets/__screenshots__/<story-path>/<theme>/<viewport>/chromium/`. Failure evidence is ignored under
`assets/.vitest/attachments/`; automatic captures use separate theme and viewport directories. Review an intentional
`--update` in Git, then run a normal comparison. The release workflow runs `just setup` and `just check` in the same
flake on pull requests and release pushes. It compares references without updating them and uploads only available PNG
reference, actual, diff, and failed-test attachments for seven days after its repository check fails. Trace archives,
caches, HTML bundles, and the full baseline catalog are excluded. Docker publication requires all checks and builds to
pass. Generate and compare references in the Linux flake environment.

Pass `--reporter=html` to write `assets/.vitest/report/index.html`. The report includes screenshot attachments and
comparison controls. Serve the report over HTTP:

```bash
just assets vite preview --outDir .vitest/report --port 4173
```

Open the URL printed by Vite. HTML reports remain a local inspection option. Vitest and Playwright E2E tracing are
disabled; E2E captures screenshots only on failure. The release gate runs Vitest, while E2E remains a separate command.

See [story conventions](assets/stories/README.md) for fixture, interaction, and screenshot guidelines.

## Music Providers

Provider selection is defined in the application config.

### Spotify

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app
3. Add `http://localhost:4000/auth/spotify/callback` to redirect URIs
4. Set environment variables:

   ```bash
   SPOTIFY_CLIENT_ID=your_client_id
   SPOTIFY_SECRET_KEY=your_client_secret
   ```

### Apple Music

Requires Apple Music API developer token:

```bash
APPLE_MUSIC_ACCESS_TOKEN=your_access_token
```

## Documentation

[OpenSpec specifications](openspec/specs/README.md)

## OpenSpec

OpenSpec is supplied by the pinned flake and is available through `nix develop` and direnv. Run
`openspec validate --all --strict --no-interactive` to validate all specifications and active changes. The release
workflow includes this validation in `just check` on pull requests and release pushes. Docker publication requires the
complete check to pass.

Run `openspec init --tools codex` after cloning to install the Codex skills locally. Start a change with
`$openspec-propose`.

## Licensing

This project is dual-licensed:

1. **GNU AGPL v3** - for open-source and non-commercial use.
2. **Commercial License** - for proprietary use without AGPL restrictions.

The commercial license allows you to:

- Use the software in proprietary products.
- Modify the code without being obligated to share changes.
- Receive priority support.

For details on the commercial license, please contact me.
