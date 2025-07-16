defmodule SongyWeb.AuthTest do
  use SongyWeb.ConnCase, async: true

  alias SongyWeb.Auth
  alias Songy.Core.User
  alias Songy.Core.Provider

  describe "fetch_current_user/2" do
    test "assigns existing user from session", %{conn: conn} do
      existing_user = User.new()

      conn =
        conn
        |> put_session(:current_user, existing_user)
        |> Auth.fetch_current_user([])

      assert conn.assigns.current_user == existing_user
    end

    test "creates new user when session is empty", %{conn: conn} do
      conn = Auth.fetch_current_user(conn, [])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.current_user.uuid)
      assert String.length(conn.assigns.current_user.uuid) == 32
    end

    test "creates new user when session has nil", %{conn: conn} do
      conn =
        conn
        |> put_session(:current_user, nil)
        |> Auth.fetch_current_user([])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.current_user.uuid)
    end
  end

  describe "put_user_token/2" do
    test "creates user token from user uuid", %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> assign(:current_user, user)
        |> Auth.put_user_token([])

      assert is_binary(conn.assigns.user_token)

      # Verify token can be verified with new structure
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == user.uuid
    end

    test "works with user from session", %{conn: conn} do
      user = User.new()

      conn =
        conn
        |> put_session(:current_user, user)
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert is_binary(conn.assigns.user_token)

      # Verify token integrity
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == user.uuid
    end

    test "generates different tokens for different users", %{conn: conn} do
      user1 = User.new()
      user2 = User.new()

      conn1 =
        conn
        |> assign(:current_user, user1)
        |> Auth.put_user_token([])

      conn2 =
        conn
        |> assign(:current_user, user2)
        |> Auth.put_user_token([])

      assert conn1.assigns.user_token != conn2.assigns.user_token

      # Verify both tokens work correctly
      {:ok, user_uuid1} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn1.assigns.user_token)

      {:ok, user_uuid2} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn2.assigns.user_token)

      assert user_uuid1 == user1.uuid
      assert user_uuid2 == user2.uuid
    end

    test "returns conn unchanged when no current_user", %{conn: conn} do
      conn_result = Auth.put_user_token(conn, [])
      assert conn_result == conn
      refute Map.has_key?(conn_result.assigns, :user_token)
    end
  end

  describe "put_provider_token/2" do
    test "creates provider token when provider exists", %{conn: conn} do
      provider = %{type: :spotify, data: %{token: "abc123"}}

      conn =
        conn
        |> assign(:provider, provider)
        |> Auth.put_provider_token([])

      assert is_binary(conn.assigns.provider_token)

      # Verify token can be verified
      {:ok, verified_provider} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_provider", conn.assigns.provider_token)

      assert verified_provider == provider
    end

    test "returns conn unchanged when no provider", %{conn: conn} do
      conn_result = Auth.put_provider_token(conn, [])
      assert conn_result == conn
      refute Map.has_key?(conn_result.assigns, :provider_token)
    end

    test "returns conn unchanged when provider is nil", %{conn: conn} do
      conn_result =
        conn
        |> assign(:provider, nil)
        |> Auth.put_provider_token([])

      assert conn_result.assigns.provider == nil
      refute Map.has_key?(conn_result.assigns, :provider_token)
    end
  end

  describe "plug pipeline integration" do
    test "fetch_current_user and put_user_token work together", %{conn: conn} do
      conn =
        conn
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert %User{} = conn.assigns.current_user
      assert is_binary(conn.assigns.user_token)

      # Verify token matches user
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == conn.assigns.current_user.uuid
    end

    test "preserves existing user through pipeline", %{conn: conn} do
      original_user = User.new()

      conn =
        conn
        |> put_session(:current_user, original_user)
        |> Auth.fetch_current_user([])
        |> Auth.put_user_token([])

      assert conn.assigns.current_user == original_user

      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      assert user_uuid == original_user.uuid
    end

    test "both tokens work together in pipeline", %{conn: conn} do
      user = User.new()
      provider = %{type: :spotify, data: %{token: "abc123"}}

      conn =
        conn
        |> assign(:current_user, user)
        |> assign(:provider, provider)
        |> Auth.put_user_token([])
        |> Auth.put_provider_token([])

      assert is_binary(conn.assigns.user_token)
      assert is_binary(conn.assigns.provider_token)

      # Verify both tokens work correctly
      {:ok, user_uuid} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_user", conn.assigns.user_token)

      {:ok, verified_provider} =
        Phoenix.Token.verify(SongyWeb.Endpoint, "current_provider", conn.assigns.provider_token)

      assert user_uuid == user.uuid
      assert verified_provider == provider
    end
  end

  describe "fetch_current_provider/2" do
    test "assigns existing valid provider from session", %{conn: conn} do
      future_time = DateTime.utc_now() |> DateTime.add(3600, :second)
      credentials = %{access_token: "valid_token", expires_at: future_time}
      provider = Provider.new(:spotify, credentials)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == provider
    end

    test "assigns nil when no provider in session", %{conn: conn} do
      conn = Auth.fetch_current_provider(conn, [])

      assert conn.assigns.provider == nil
    end

    test "handles unsupported provider types", %{conn: conn} do
      unsupported_provider = Provider.new(:youtube, %{token: "token"})

      conn =
        conn
        |> put_session(:provider, unsupported_provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == nil
      assert get_session(conn, :provider) == nil
    end
  end

  describe "spotify integration" do
    test "assigns provider when tokens are not close to expiry", %{conn: conn} do
      # 30 minutes from now
      future_time = DateTime.utc_now() |> DateTime.add(1800, :second)

      credentials = %{
        access_token: "valid_token",
        refresh_token: "refresh_token",
        expires_at: future_time
      }

      provider = Provider.new(:spotify, credentials)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == provider
      assert get_session(conn, :provider) == provider
    end

    test "attempts to refresh tokens when close to expiry", %{conn: conn} do
      # Token expires in 200 seconds (within refresh threshold)
      expires_soon = DateTime.utc_now() |> DateTime.add(200, :second)

      # Create provider with correct structure
      provider = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{
          access_token: "old_token",
          refresh_token: "refresh_token",
          expires_at: expires_soon
        }
      }

      Repatch.patch(Spotify.Authentication, :refresh, fn _creds ->
        {:ok,
         %Spotify.Credentials{
           access_token: "new_token",
           refresh_token: "new_refresh_token"
         }}
      end)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert %Provider{} = conn.assigns.provider
      assert conn.assigns.provider.meta.access_token == "new_token"
      assert conn.assigns.provider.meta.refresh_token == "new_refresh_token"
    end

    test "handles case when exist only refresh_token", %{conn: conn} do
      provider = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{refresh_token: "refresh_token"}
      }

      Repatch.patch(Spotify.Authentication, :refresh, fn _creds ->
        {:ok,
         %Spotify.Credentials{
           access_token: "new_token",
           refresh_token: "new_refresh_token"
         }}
      end)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert %Provider{} = conn.assigns.provider
      assert conn.assigns.provider.meta.access_token == "new_token"
      assert conn.assigns.provider.meta.refresh_token == "new_refresh_token"
    end

    test "handles case when missing refresh_token", %{conn: conn} do
      invalid_provider = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{access_token: "token", expires_at: DateTime.utc_now()}
      }

      conn =
        conn
        |> put_session(:provider, invalid_provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == nil
      assert get_session(conn, :provider) == nil
    end

    @tag :only
    test "handles case when provider has empty meta", %{conn: conn} do
      provider = Provider.new(:spotify)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == nil
      assert get_session(conn, :provider) == nil
    end

    test "clears session when provider has nil values", %{conn: conn} do
      conn = Auth.fetch_current_provider(conn, [])

      assert conn.assigns.provider == nil
      assert get_session(conn, :provider) == nil
    end

    test "preserves existing expires_at when token is valid", %{conn: conn} do
      original_expires_at = DateTime.utc_now() |> DateTime.add(1800, :second)

      provider_with_expires = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{
          access_token: "valid_token",
          refresh_token: "refresh_token",
          expires_at: original_expires_at
        }
      }

      conn =
        conn
        |> put_session(:provider, provider_with_expires)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider.meta.expires_at == original_expires_at
      assert conn.assigns.provider == provider_with_expires
    end

    test "removes provider when token expiry is close and no refresh_token", %{conn: conn} do
      expires_soon = DateTime.utc_now() |> DateTime.add(200, :second)

      invalid_provider = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{
          access_token: "token_without_refresh",
          expires_at: expires_soon
        }
      }

      conn =
        conn
        |> put_session(:provider, invalid_provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == nil
      assert get_session(conn, :provider) == nil
    end

    test "handles token refresh failure gracefully", %{conn: conn} do
      expires_soon = DateTime.utc_now() |> DateTime.add(200, :second)

      provider = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{
          access_token: "expiring_token",
          refresh_token: "refresh_token",
          expires_at: expires_soon
        }
      }

      Repatch.patch(Spotify.Authentication, :refresh, fn _creds ->
        :unauthorized
      end)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider == nil
      assert get_session(conn, :provider) == nil
    end

    test "handles exact threshold boundary for token expiry", %{conn: conn} do
      expires_at_threshold = DateTime.utc_now() |> DateTime.add(300, :second)

      provider = %Provider{
        id: :spotify,
        meta: %Songy.Core.Provider.Spotify{
          access_token: "boundary_token",
          refresh_token: "refresh_token",
          expires_at: expires_at_threshold
        }
      }

      Repatch.patch(Spotify.Authentication, :refresh, fn _creds ->
        {:ok,
         %Spotify.Credentials{
           access_token: "boundary_refreshed_token",
           refresh_token: "boundary_refresh_token"
         }}
      end)

      conn =
        conn
        |> put_session(:provider, provider)
        |> Auth.fetch_current_provider([])

      assert conn.assigns.provider.meta.access_token == "boundary_refreshed_token"
    end
  end

  describe "require_provider/2" do
    test "allows request when provider is present", %{conn: conn} do
      provider = Provider.new(:spotify, %{access_token: "valid_token"})

      conn =
        conn
        |> assign(:provider, provider)
        |> Auth.require_provider([])

      assert conn.assigns.provider == provider
      refute conn.halted
    end

    test "redirects to home with error when provider is nil", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> assign(:provider, nil)
        |> Auth.require_provider([])

      assert conn.halted
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be authenticated by one of the supported providers."
    end

    test "redirects to home with error when provider is not assigned", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> Auth.require_provider([])

      assert conn.halted
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be authenticated by one of the supported providers."
    end

    test "works with different provider types", %{conn: conn} do
      spotify_provider = Provider.new(:spotify, %{access_token: "spotify_token"})

      conn =
        conn
        |> assign(:provider, spotify_provider)
        |> Auth.require_provider([])

      assert conn.assigns.provider.id == :spotify
      refute conn.halted
    end

    test "preserves existing flash messages when provider is present", %{conn: conn} do
      provider = Provider.new(:spotify, %{access_token: "token"})

      conn =
        conn
        |> fetch_flash()
        |> put_flash(:info, "Existing message")
        |> assign(:provider, provider)
        |> Auth.require_provider([])

      assert Phoenix.Flash.get(conn.assigns.flash, :info) == "Existing message"
      refute conn.halted
    end

    test "overwrites existing error flash when provider is missing", %{conn: conn} do
      conn =
        conn
        |> fetch_flash()
        |> put_flash(:error, "Previous error")
        |> Auth.require_provider([])

      assert conn.halted

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be authenticated by one of the supported providers."
    end
  end
end
