defmodule Owl.VehiclesDate.Schema do
  @moduledoc false
  use Owl.Schema

  alias Owl.Causalities.Schema, as: CausalitiesSchema
  alias Owl.Collisions.Schema, as: CollisionsSchema

  schema "vehicle_dates" do
    field :vehicle_id, :integer
    field :collision_id, :integer
    field :year, :integer
    field :type, :integer
    field :tow, :integer
    field :manoeuver, :integer
    field :location, :integer
    field :junction, :integer
    field :skid, :integer
    field :hit, :integer
    field :leave, :integer
    field :hit_off, :integer
    field :impact, :integer
    field :sex, :integer
    field :age_group, :integer
    field :hit_run, :integer
    field :foreign_reg, :integer

    belongs_to :collision, CollisionsSchema, foreign_key: :collision_uuid, references: :uuid
    has_many :casualties, CausalitiesSchema, foreign_key: :uuid
    timestamps()
  end
end
