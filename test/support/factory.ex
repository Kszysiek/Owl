defmodule Owl.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Owl.Repo

  alias Owl.Collisions.Schema

  def collision_factory do
    %Schema{
      uuid: Ecto.UUID.generate(),
      collision_id: sequence(:collision_id, & &1),
      year: Enum.random(2017..2022),
      month: Enum.random(1..12),
      day: Enum.random(1..28),
      hour: Enum.random(0..23),
      min: Enum.random(0..59),
      district: sequence(:district, &"District #{&1}"),
      severity: Enum.random([:fatal, :serious, :slight]),
      total_casualties: Enum.random(1..10),
      weather: Enum.random(["Fine", "Raining", "Fog", "Snow", nil]),
      road_surface: Enum.random(["Dry", "Wet", "Icy", nil]),
      light_conditions: Enum.random(["Daylight", "Darkness - lights lit", "Darkness - no lighting", nil]),
      speed_limit: Enum.random([20, 30, 40, 50, 60, 70])
    }
  end
end
