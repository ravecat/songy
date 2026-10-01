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
just serve
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
just serve
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

`just setup` installs Hex, Rebar, Mix dependencies, and frontend dependencies using the Bun lockfile. `just serve` also
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
just assets test:storybook
just assets check --watch
just assets typecheck
just assets e2e --reporter=list
just assets e2e --ui
just assets codegen
just assets build
```

`just format` formats Elixir and Markdown. `just check` validates OpenSpec, then runs backend formatting, compilation
and tests, Markdown formatting, Svelte/TypeScript checks, frontend tests, and production frontend/Storybook builds. The
flake provides Chromium matching the pinned Playwright dependency. For a production release, run `just assets deploy`
followed by `MIX_ENV=prod just mix phx.digest`; Docker does both before building the release. The Docker builder retains
d20's release image with Elixir 1.19.5 and OTP 28.3.3 and installs Bun 1.3.13 separately.

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
workflow runs this command in the flake on pull requests and release pushes. Docker publication requires this validation
to pass.

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
