defmodule Owl.Repo.Migrations.AddVehiclesTable do
  use Ecto.Migration

  def change do
    create table(:vehicles, primary_key: false) do
      add :col, :string, primary_key: true
      add :code, :integer, primary_key: true
      add :name, :string

      timestamps()
    end
  end
end
