defmodule Owl.Collisions.Schema do
  @moduledoc false
  use Owl.Schema

  alias Owl.VehiclesDate.Schema, as: VehiclesDateSchema

  schema "collisions" do
    # Identity
    field :collision_id, :integer
    field :year, :integer
    field :month, :integer
    field :day, :integer
    field :hour, :integer
    field :min, :integer
    field :weekday, :string

    # Location
    field :district, :string
    field :grid_ref_1, :integer
    field :grid_ref_2, :integer
    field :junction_detail, :string
    field :junction_control, :string

    # Conditions
    field :speed_limit, :integer
    field :light_conditions, :string
    field :weather, :string
    field :road_surface, :string
    field :special_conditions, :string
    field :carriageway_hazards, :string

    # Pedestrian facilities
    field :pedestrian_crossing_human, :string
    field :pedestrian_crossing_physical, :string

    # Summary
    field :total_vehicles, :integer
    field :total_casualties, :integer
    field :collision_type, :string

    field :severity, Ecto.Enum,
      values: [
        fatal: "Fatal injury collision",
        serious: "Serious injury collision",
        slight: "Slight injury collision"
      ]

    field :police_attended_scene, :boolean

    has_many :vehicle_dates, VehiclesDateSchema, foreign_key: :uuid

    timestamps()
  end
end
