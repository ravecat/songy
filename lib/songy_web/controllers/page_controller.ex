defmodule SongyWeb.PageController do
  use SongyWeb, :controller

  alias Songy.Boundary.GameSession
  alias Songy.Music

  def home(conn, _params) do
    user_id = conn.assigns.current_user.id

    conn
    |> assign_prop(:tracks, inertia_defer(fn -> Music.search_cover_tracks(user_id) end))
    |> render_inertia("home")
  end

  def create(conn, _params) do
    user_id = conn.assigns.current_user.id

    case GameSession.create_game_session(user_id) do
      {:ok, game} ->
        redirect(conn, to: ~p"/#{game.id}")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to create game session: #{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  def join(conn, %{"room_id" => room_id}) do
    case GameSession.get_state(room_id) do
      {:ok, game} ->
        room_url = url(conn, ~p"/#{game.id}")

        {:ok, qr_svg} = generate_room_qr(room_url)

        conn
        |> assign_prop(:room_id, game.id)
        |> assign_prop(:qr, qr_svg)
        |> render_inertia("room")

      {:error, :game_session_not_found} ->
        conn
        |> put_flash(:error, "Game session not found")
        |> redirect(to: ~p"/")

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to access game session: #{reason}")
        |> redirect(to: ~p"/")
    end
  end

  defp generate_room_qr(room_url) do
    room_url
    |> QRCode.create(:low)
    |> QRCode.render(:svg, %QRCode.Render.SvgSettings{
      background_color: "transparent",
      structure: :minify,
      flatten: true,
      quiet_zone: 1
    })
    |> then(fn
      {:ok, svg} ->
        {:ok,
         case Regex.run(~r/width="(\d+)"/, svg, capture: :all_but_first) do
           [size] ->
             svg
             |> String.replace(~r/\swidth="\d+"/, "")
             |> String.replace(~r/\sheight="\d+"/, "")
             |> String.replace(
               "<svg ",
               ~s(<svg viewBox="0 0 #{size} #{size}" ),
               global: false
             )

           _ ->
             svg
         end}

      error ->
        error
    end)
  end
end
