defmodule SongyWeb.ErrorJSONTest do
  use SongyWeb.ConnCase, async: true

  test "renders 404" do
    assert SongyWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert SongyWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
