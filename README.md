# Songy

Music application with Spotify integration built with Phoenix Framework.

## Setup

1. Clone the repository
2. Install dependencies:

   ```bash
   mix deps.get
   ```

3. Setup database:

   ```bash
   mix ecto.setup
   ```

4. Configure Spotify API:

   - Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Create a new app
   - Copy `.env.example` to `.env` and fill in your credentials:
     ```bash
     cp .env.example .env
     ```
   - Edit `.env` with your Spotify app credentials
   - Add `http://localhost:4000/auth/spotify/callback` to your Spotify app's redirect URIs

5. Start the server:
   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Features

- Spotify OAuth authentication
- View user profile
- Access user playlists
- Modern UI with DaisyUI and TailwindCSS

## Environment Variables

Create a `.env` file with the following variables:

- `SPOTIFY_CLIENT_ID` - Your Spotify app client ID
- `SPOTIFY_SECRET_KEY` - Your Spotify app client secret
- `SPOTIFY_USER_ID` - Your Spotify user ID (optional)

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenixyour Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
