defmodule SongyWeb.StorybookTest do
  use SongyWeb.ConnCase, async: true

  describe "call/2" do
    test "redirects /storybook to the static storybook entrypoint", %{conn: conn} do
      conn = get(conn, ~p"/storybook")

      assert redirected_to(conn) == "/storybook/index.html"
    end
  end

  describe "static_paths/0" do
    test "includes storybook assets in the endpoint whitelist" do
      assert "storybook" in SongyWeb.static_paths()
    end
  end
end
