defmodule Songy.Boundary.AppleTest do
  use ExUnit.Case, async: true

  alias Songy.Boundary.Apple

  @valid_token "test_developer_token"

  describe "search/2" do
    test "returns results when search is successful" do
      expected_response = %{
        status: 200,
        body: %{
          "results" => %{
            "songs" => %{
              "data" => [
                %{"id" => "123", "attributes" => %{"name" => "Test Song"}}
              ]
            }
          }
        }
      }

      Repatch.patch(Req, :get, fn _url, _opts -> {:ok, expected_response} end)

      assert {:ok, results} = Apple.search(@valid_token, term: "test")
      assert Map.has_key?(results, "songs")
    end

    test "returns error when API request fails" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:error, %RuntimeError{message: "Network error"}}
      end)

      assert {:error, :search_failed} = Apple.search(@valid_token, term: "test")
    end

    test "uses default storefront from config when not specified" do
      Repatch.patch(Req, :get, fn url, _opts ->
        assert url =~ "/catalog/us/search"
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(@valid_token, term: "test")
    end

    test "uses custom storefront when specified in params" do
      Repatch.patch(Req, :get, fn url, _opts ->
        assert url =~ "/catalog/gb/search"
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(@valid_token, term: "test", storefront: "gb")
    end

    test "passes query params directly to Req" do
      Repatch.patch(Req, :get, fn _url, opts ->
        params = Keyword.get(opts, :params)
        assert Keyword.get(params, :term) == "beatles"
        assert Keyword.get(params, :types) == "albums"
        assert Keyword.get(params, :limit) == 10
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(@valid_token, term: "beatles", types: "albums", limit: 10)
    end

    test "handles API error responses" do
      Repatch.patch(Req, :get, fn _url, _opts ->
        {:ok, %{status: 401, body: %{"errors" => [%{"status" => "401"}]}}}
      end)

      assert {:error, :search_failed} = Apple.search(@valid_token, term: "test")
    end

    test "includes Authorization header with Bearer token" do
      Repatch.patch(Req, :get, fn _url, opts ->
        headers = Keyword.get(opts, :headers)
        assert {"Authorization", "Bearer test_developer_token"} in headers
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(@valid_token, term: "test")
    end

    test "includes Content-Type header" do
      Repatch.patch(Req, :get, fn _url, opts ->
        headers = Keyword.get(opts, :headers)
        assert {"Content-Type", "application/json"} in headers
        {:ok, %{status: 200, body: %{"results" => %{}}}}
      end)

      Apple.search(@valid_token, term: "test")
    end
  end
end
