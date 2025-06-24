defmodule SongyWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use SongyWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint SongyWeb.Endpoint

      use SongyWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import SongyWeb.ConnCase
    end
  end

  setup tags do
    Songy.DataCase.setup_sandbox(tags)

    conn =
      Phoenix.ConnTest.build_conn()
      |> Map.put(:secret_key_base, SongyWeb.Endpoint.config(:secret_key_base))
      |> Plug.Conn.put_private(:phoenix_endpoint, SongyWeb.Endpoint)
      |> Plug.Test.init_test_session(%{})

    {:ok, conn: conn}
  end
end
