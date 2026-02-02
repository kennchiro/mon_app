defmodule MonApp.Repo do
  use Ecto.Repo,
    otp_app: :mon_app,
    adapter: Ecto.Adapters.Postgres
end
