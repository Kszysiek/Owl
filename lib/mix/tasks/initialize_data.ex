defmodule Mix.Tasks.InitializeData do
  @moduledoc false
  use Mix.Task

  def run(_args) do
    Mix.Task.run("app.start")

    Owl.Parser.VehicleIndex.parse("static/initial_data/vehicle-index.csv")
    Mix.shell().info("vehicle index imported")
    Owl.Parser.Collisions.parse("static/initial_data/collision2017-2022.csv")
    Mix.shell().info("collisions imported")
    Owl.Parser.VehicleDate.parse("static/initial_data/vehicle2017-2022.csv")
    Mix.shell().info("vehicles imported")
    Owl.Parser.Casualties.parse("static/initial_data/casualty2017-2022.csv")
    Mix.shell().info("causualities imported")
  end
end
