defmodule Owl.VehiclesDate do
  @moduledoc false
  import Ecto.Query

  alias Owl.Repo
  alias Owl.VehiclesDate.Schema
  alias Owl.VehiclesIndex.Schema, as: VehicleIndexSchema

  def list, do: Repo.all(Schema)

  def list_by_year_collision_and_vehicle(vehicle_ids, collision_ids, years) do
    Schema
    |> where([s], s.vehicle_id in ^vehicle_ids)
    |> where([s], s.year in ^years)
    |> where([s], s.collision_id in ^collision_ids)
    |> select([s], %{
      uuid: s.uuid,
      year: s.year,
      collision_id: s.collision_id,
      vehicle_id: s.vehicle_id
    })
    |> Repo.all()
    |> Map.new(&{{&1.vehicle_id, &1.collision_id, &1.year}, &1.uuid})
  end

  def list_vehicle_types_with_collision_id(collision_id, collision_year) do
    Schema
    |> where([vd], vd.collision_uuid == ^collision_id)
    |> where([vd], vd.year == ^collision_year)
    |> join(:inner, [vd], vi in VehicleIndexSchema, on: vd.type == vi.code and vi.col == "v_type")
    |> select([_vd, vi], vi.name)
    |> distinct(true)
    |> Repo.all()
  end
end
