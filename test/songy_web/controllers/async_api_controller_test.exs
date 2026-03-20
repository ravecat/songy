defmodule SongyWeb.AsyncApiControllerTest do
  use SongyWeb.ConnCase

  describe "GET /api/asyncapi" do
    test "returns the AsyncAPI HTML UI", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/html")
        |> get("/api/asyncapi")

      body = response(conn, 200)

      assert body =~ "AsyncAPI Reference"
      assert body =~ "/api/asyncapi/raw"
      assert body =~ "@asyncapi/react-component"
      assert get_resp_header(conn, "content-type") |> List.first() =~ "text/html"
    end
  end

  describe "GET /api/asyncapi/raw" do
    test "returns the AsyncAPI yaml spec", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "text/yaml")
        |> get("/api/asyncapi/raw")

      assert response(conn, 200) =~ "asyncapi: 3.0.0"
      assert get_resp_header(conn, "content-type") |> List.first() =~ "text/yaml"
    end
  end
end
