defmodule WordexBlast.Repo do
  use Ecto.Repo,
    otp_app: :wordex_blast,
    adapter: Ecto.Adapters.Postgres
end
