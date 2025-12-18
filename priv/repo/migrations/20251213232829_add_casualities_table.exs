defmodule Owl.Repo.Migrations.AddCasualitiesTable do
  use Ecto.Migration

  def change do
    create table(:casualties) do
      add :casualty_id, :integer
      add :collision_id, :integer
      add :vehicle_id, :integer
      add :year, :integer

      add :class, :string
      add :sex, :string
      add :age_group, :string
      add :severity, :string
      add :location, :string
      add :movement, :string
      add :school, :string
      add :pcv, :string
      add :ped_injury, :string
      add :vehicle_type, :string

      add :vehicle_uuid,
          references(:vehicle_dates),
          null: true

      timestamps()
    end

    create unique_index(:casualties, [:casualty_id, :vehicle_id, :collision_id, :year],
             name: :casualties_casualty_vehicle_collision_year_unique_index
           )
  end
end
