defmodule Owl.Repo.Migrations.AddVehiclesDateTable do
  use Ecto.Migration

  def change do
    create table(:vehicle_dates) do
      add :vehicle_id, :integer
      add :collision_id, :integer
      add :year, :integer
      add :type, :integer
      add :tow, :integer
      add :manoeuver, :integer
      add :location, :integer
      add :junction, :integer
      add :skid, :integer
      add :hit, :integer
      add :leave, :integer
      add :hit_off, :integer
      add :impact, :integer
      add :sex, :integer
      add :age_group, :integer
      add :hit_run, :integer
      add :foreign_reg, :integer

      add :collision_uuid,
          references(:collisions),
          null: true

      timestamps()
    end

    create unique_index(:vehicle_dates, [:vehicle_id, :year, :collision_id],
             name: :vehicle_dates_collision_unique_index
           )
  end
end
