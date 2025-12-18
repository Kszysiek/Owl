defmodule Owl.Parser.VehicleDate do
  @moduledoc false
  import Owl.Parser.Utils

  alias Owl.Parser.CsvParser
  alias Owl.Repo
  alias Owl.VehiclesDate.Schema

  @priv_dir "priv"
  @chunk_size 1000

  def parse(path) do
    :owl
    |> Application.app_dir(@priv_dir)
    |> Path.join(path)
    |> parse_csv_stream()
    |> Stream.chunk_every(@chunk_size)
    |> Enum.each(&insert_vehicle_date(&1))
  end

  defp insert_vehicle_date(vehicle_date_chunk) do
    {collision_ids, years} = extract_collision_ids_and_years(vehicle_date_chunk)

    collision_uuid_by_collision_id_and_year =
      Owl.Collisions.list_uuids_by_collision_id_and_year(collision_ids, years)

    insert_params = Enum.map(vehicle_date_chunk, &build_insert_params(&1, collision_uuid_by_collision_id_and_year))

    now = DateTime.utc_now()
    placeholders = %{now: now}

    Repo.insert_all(Schema, insert_params, placeholders: placeholders)
  end

  defp build_insert_params(
         %{year: year, collision_id: collision_id} = parsed_csv_row,
         collision_uuid_by_collision_id_and_year
       ) do
    parsed_csv_row
    |> Map.put(:uuid, Ecto.UUID.generate())
    |> Map.put(:collision_uuid, Map.get(collision_uuid_by_collision_id_and_year, {collision_id, year}))
    |> Map.put(:inserted_at, {:placeholder, :now})
    |> Map.put(:updated_at, {:placeholder, :now})
  end

  defp extract_collision_ids_and_years(vehicle_dates) do
    {collision_ids, years} =
      Enum.reduce(vehicle_dates, {[], []}, fn %{year: year, collision_id: collision_id}, {collision_ids, years} ->
        {[collision_id | collision_ids], [year | years]}
      end)

    {Enum.uniq(collision_ids), Enum.uniq(years)}
  end

  defp parse_csv_stream(path) do
    path
    |> File.stream!()
    |> CsvParser.parse_stream(skip_headers: true)
    |> Stream.map(fn vehicle_date_row ->
      Enum.map(vehicle_date_row, &nil_or_integer/1)
    end)
    |> Stream.map(&parse_csv_row/1)
  end

  defp parse_csv_row([
         a_year,
         a_ref,
         v_id,
         v_type,
         v_tow,
         v_man,
         v_loc,
         v_junc,
         v_skid,
         v_hit,
         v_leave,
         v_hitoff,
         v_impact,
         v_sex,
         v_agegroup,
         v_hitr,
         v_forreg
       ]) do
    %{
      vehicle_id: v_id,
      collision_id: a_ref,
      year: a_year,
      type: v_type,
      tow: v_tow,
      manoeuver: v_man,
      location: v_loc,
      junction: v_junc,
      skid: v_skid,
      hit: v_hit,
      leave: v_leave,
      hit_off: v_hitoff,
      impact: v_impact,
      sex: v_sex,
      age_group: v_agegroup,
      hit_run: v_hitr,
      foreign_reg: v_forreg
    }
  end
end
