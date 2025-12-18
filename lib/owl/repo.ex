defmodule Owl.Repo do
  use Ecto.Repo,
    otp_app: :owl,
    adapter: Ecto.Adapters.Postgres
end
