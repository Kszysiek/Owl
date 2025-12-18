defmodule Owl.Causalities.Schema do
  @moduledoc false
  use Owl.Schema

  alias Owl.VehiclesDate.Schema, as: VehicleDateSchema

  schema "casualties" do
    field :casualty_id, :integer
    field :vehicle_id, :integer
    field :collision_id, :integer
    field :year, :integer

    field :class, :string
    field :sex, :string
    field :age_group, :string
    field :severity, :string
    field :location, :string
    field :movement, :string
    field :school, :string
    field :pcv, :string
    field :ped_injury, :string
    field :vehicle_type, :string

    belongs_to :vehicle, VehicleDateSchema, foreign_key: :vehicle_uuid, references: :uuid

    timestamps()
  end
end
