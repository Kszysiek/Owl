defmodule Owl.VehiclesIndex.Schema do
  @moduledoc false

  use Owl.Schema

  @primary_key false

  schema "vehicles" do
    field :col, :string, primary_key: true
    field :code, :integer, primary_key: true
    field :name, :string

    timestamps()
  end
end
