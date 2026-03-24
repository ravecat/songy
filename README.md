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
mix setup
mix phx.server
```

If you need Storybook, run it in a separate terminal:

```bash
mix storybook
```

**Without direnv (manual):**

```bash
cd songy/
nix develop
mix setup
mix phx.server
```

If you need Storybook, run it in a separate terminal:

```bash
mix storybook
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Music Providers

By default, the app uses **iTunes** (no configuration needed) - its rate limits are sufficient for development.

For production or enhanced features, configure one of these providers:

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

[docs/README.md](docs/README.md)

## Licensing

This project is dual-licensed:

1. **GNU AGPL v3** - for open-source and non-commercial use.
2. **Commercial License** - for proprietary use without AGPL restrictions.

The commercial license allows you to:

- Use the software in proprietary products.
- Modify the code without being obligated to share changes.
- Receive priority support.

For details on the commercial license, please contact me.
