# Songy

Music quiz application with Spotify integration built with Phoenix Framework.

## Setup

1. Clone the repository
2. Install dependencies:

   ```bash
   mix deps.get
   ```

3. Configure Spotify API:

   - Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Create a new app
   - Copy `.env.example` to `.env` and fill in your credentials:

     ```bash
     cp .env.example .env
     ```

   - Edit `.env` with your Spotify app credentials
   - Add `http://localhost:4000/auth/spotify/callback` to your Spotify app's redirect URIs

4. Start the server:

   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Environment Variables

Create a `.env` file with the following variables:

- `SPOTIFY_CLIENT_ID` - Your Spotify app client ID
- `SPOTIFY_SECRET_KEY` - Your Spotify app client secret
- `SPOTIFY_USER_ID` - Your Spotify user ID (optional)

## Licensing

This project is dual-licensed:

1. **GNU AGPL v3** - for open-source and non-commercial use.
2. **Commercial License** - for proprietary use without AGPL restrictions.

The commercial license allows you to:

- Use the software in proprietary products.
- Modify the code without being obligated to share changes.
- Receive priority support.

For details on the commercial license, please contact me.
