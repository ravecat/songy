defmodule Songy.Repo do
  use Ecto.Repo,
    otp_app: :songy,
    adapter: Ecto.Adapters.Postgres
end
