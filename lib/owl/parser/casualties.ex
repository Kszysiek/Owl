defmodule Owl.Parser.Casualties do
  @moduledoc false
  import Owl.Parser.Utils

  alias Owl.Causalities.Schema
  alias Owl.Parser.CsvParser
  alias Owl.Repo

  @priv_dir "priv"

  @chunk_size 1000

  def parse(path) do
    :owl
    |> Application.app_dir(@priv_dir)
    |> Path.join(path)
    |> parse_csv_stream()
    |> Stream.chunk_every(@chunk_size)
    |> Enum.each(&insert_casualties(&1))
  end

  defp parse_csv_stream(path) do
    path
    |> File.stream!()
    |> CsvParser.parse_stream(skip_headers: true)
    |> Stream.map(&parse_csv_row/1)
  end

  defp insert_casualties(casualties_chunk) do
    now = DateTime.utc_now()
    placeholders = %{now: now}

    {collision_ids, vehicle_ids, years} = extract_collision_id_year_and_vehicle_id(casualties_chunk)

    vehicle_date_uuid_by_vehicle_collision_and_year =
      Owl.VehiclesDate.list_by_year_collision_and_vehicle(vehicle_ids, collision_ids, years)

    insert_params = Enum.map(casualties_chunk, &build_insert_params(&1, vehicle_date_uuid_by_vehicle_collision_and_year))

    Repo.insert_all(Schema, insert_params, placeholders: placeholders)
  end

  defp build_insert_params(
         %{year: year, collision_id: collision_id, vehicle_id: vehicle_id} = parsed_csv_row,
         vehicle_date_uuid_by_vehicle_collision_and_year
       ) do
    parsed_csv_row
    |> Map.put(:uuid, Ecto.UUID.generate())
    |> Map.put(:vehicle_uuid, Map.get(vehicle_date_uuid_by_vehicle_collision_and_year, {vehicle_id, collision_id, year}))
    |> Map.put(:inserted_at, {:placeholder, :now})
    |> Map.put(:updated_at, {:placeholder, :now})
  end

  defp extract_collision_id_year_and_vehicle_id(casualties) do
    {collision_ids, vehicle_ids, years} =
      Enum.reduce(casualties, {[], [], []}, fn %{collision_id: collision_id, vehicle_id: vehicle_id, year: year},
                                               {collision_ids, vehicle_ids, years} ->
        {[collision_id | collision_ids], [vehicle_id | vehicle_ids], [year | years]}
      end)

    {Enum.uniq(collision_ids), Enum.uniq(vehicle_ids), Enum.uniq(years)}
  end

  defp parse_csv_row([
         a_year,
         a_ref,
         v_id,
         c_id,
         c_class,
         c_sex,
         c_agegroup,
         c_sever,
         c_loc,
         c_move,
         c_school,
         c_pcv,
         c_pedinj,
         c_vtype
       ]) do
    %{
      collision_id: nil_or_integer(a_ref),
      casualty_id: nil_or_integer(c_id),
      year: nil_or_integer(a_year),
      class: nil_or_string(c_class),
      sex: nil_or_string(c_sex),
      age_group: nil_or_string(c_agegroup),
      severity: nil_or_string(c_sever),
      location: nil_or_string(c_loc),
      movement: nil_or_string(c_move),
      school: nil_or_string(c_school),
      pcv: nil_or_string(c_pcv),
      ped_injury: nil_or_string(c_pedinj),
      vehicle_type: nil_or_string(c_vtype),
      vehicle_id: nil_or_integer(v_id)
    }
  end
end
