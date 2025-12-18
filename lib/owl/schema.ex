defmodule Owl.Schema do
  @moduledoc false

  defmacro __using__(opts) do
    quote do
      use Ecto.Schema

      import Ecto.Changeset

      alias Owl.Repo

      @opts unquote(opts)

      @primary_key Keyword.get(
                     @opts,
                     :primary_key,
                     {:uuid, Ecto.UUID, autogenerate: true}
                   )
      @foreign_key_type Keyword.get(@opts, :foreign_key_type, Ecto.UUID)
      @datetime_type Keyword.get(@opts, :datetime_type, :utc_datetime_usec)
      @timestamps_opts [type: @datetime_type]
    end
  end
end
