defmodule SongyWeb.SpotifyControllerTest do
  use SongyWeb.ConnCase

  alias Songy.Core.User

  describe "authorize/2" do
    test "redirects to Spotify authorization URL", %{conn: conn} do
      conn = get(conn, ~p"/auth/spotify/")

      assert redirected_to(conn, 302) =~ "https://accounts.spotify.com/authorize"
    end
  end

  describe "callback/2" do
    setup %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> assign(:current_user, user)
        |> fetch_flash()
        |> put_session(:current_user, user)

      %{conn: conn, user: user}
    end

    test "redirects to home with success message on successful authentication", %{conn: conn} do
      Repatch.patch(Spotify.Credentials, :new, fn _conn -> %{test: "credentials"} end)

      Repatch.patch(Songy.Boundary.Spotify, :authenticate, fn _creds, _params ->
        {:ok, %{access_token: "token123"}}
      end)

      Repatch.patch(Songy.Providers, :insert, fn _registry, _user_uuid, _provider, _data ->
        :ok
      end)

      conn = get(conn, ~p"/auth/spotify/callback", %{"code" => "valid_code"})

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully connected to Spotify!"
    end

    test "redirects to home with error message on authentication failure", %{conn: conn} do
      Repatch.patch(Spotify.Credentials, :new, fn _conn -> %{test: "credentials"} end)

      Repatch.patch(Songy.Boundary.Spotify, :authenticate, fn _creds, _params ->
        {:error, :invalid_grant}
      end)

      conn = get(conn, ~p"/auth/spotify/callback", %{"code" => "invalid_code"})

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Failed to authenticate with Spotify. Please try again."
    end

    test "redirects to home with error message on ETS insert failure", %{conn: conn} do
      Repatch.patch(Spotify.Credentials, :new, fn _conn -> %{test: "credentials"} end)

      Repatch.patch(Songy.Boundary.Spotify, :authenticate, fn _creds, _params ->
        {:ok, %{access_token: "token123"}}
      end)

      Repatch.patch(Songy.Providers, :insert, fn _registry, _user_uuid, _provider, _data ->
        {:error, :ets_failure}
      end)

      conn = get(conn, ~p"/auth/spotify/callback", %{"code" => "some_code"})

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Failed to authenticate with Spotify. Please try again."
    end

    test "stores credentials in ETS on successful authentication", %{conn: conn, user: user} do
      credentials_map = %{
        access_token: "successful_token",
        refresh_token: "refresh_token_123",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
      }

      Repatch.patch(Spotify.Credentials, :new, fn _conn -> %{test: "credentials"} end)

      Repatch.patch(Songy.Boundary.Spotify, :authenticate, fn _creds, _params ->
        {:ok, credentials_map}
      end)

      conn = get(conn, ~p"/auth/spotify/callback", %{"code" => "valid_auth_code"})

      assert {:ok, {:spotify, stored_credentials}} = Songy.Providers.lookup(:providers, user.uuid)
      assert stored_credentials.access_token == "successful_token"
      assert stored_credentials.refresh_token == "refresh_token_123"
      assert stored_credentials.expires_at == credentials_map.expires_at

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Successfully connected to Spotify!"
    end

    test "handles OAuth error gracefully", %{conn: conn} do
      conn = get(conn, ~p"/auth/spotify/callback", %{"error" => "access_denied"})

      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Authentication was cancelled or failed."
    end
  end

  describe "disconnect/2" do
    test "disconnects from Spotify and redirects", %{conn: conn} do
      conn = delete(conn, ~p"/auth/spotify/disconnect")

      assert redirected_to(conn) == "/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Disconnected from Spotify."
    end
  end
end
