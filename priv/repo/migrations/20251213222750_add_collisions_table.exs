defmodule Owl.Repo.Migrations.AddCollisionsTable do
  use Ecto.Migration

  def change do
    create table(:collisions) do
      add :collision_id, :integer
      add :year, :integer
      add :month, :integer
      add :day, :integer
      add :hour, :integer
      add :min, :integer
      add :weekday, :string
      add :district, :string
      add :grid_ref_1, :integer
      add :grid_ref_2, :integer
      add :junction_detail, :string
      add :junction_control, :string
      add :speed_limit, :integer
      add :light_conditions, :string
      add :weather, :string
      add :road_surface, :string
      add :special_conditions, :string
      add :carriageway_hazards, :string
      add :pedestrian_crossing_human, :string
      add :pedestrian_crossing_physical, :string
      add :total_vehicles, :integer
      add :total_casualties, :integer
      add :collision_type, :string
      add :severity, :string
      add :police_attended_scene, :boolean

      timestamps()
    end

    create unique_index(:collisions, [:collision_id, :year],
             name: :collisions_collision_year_unique
           )

    create index(:collisions, [:year, :severity])
  end
end
