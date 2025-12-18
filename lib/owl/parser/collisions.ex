defmodule Owl.Parser.Collisions do
  @moduledoc false
  import Owl.Parser.Utils

  alias Owl.Collisions.Schema
  alias Owl.Repo

  @priv_dir "priv"
  @chunk_size 1000

  def parse(path) do
    :owl
    |> Application.app_dir(@priv_dir)
    |> Path.join(path)
    |> File.stream!()
    |> Owl.Parser.CsvParser.parse_stream(skip_headers: true)
    |> Stream.map(fn [
                       a_year,
                       a_ref,
                       a_district,
                       a_type,
                       a_veh,
                       a_cas,
                       a_wkday,
                       a_day,
                       a_month,
                       a_hour,
                       a_min,
                       a_gd1,
                       a_gd2,
                       a_ctype,
                       a_speed,
                       a_jdet,
                       a_jcont,
                       a_pedhum,
                       a_pedphys,
                       a_light,
                       a_weat,
                       a_roadsc,
                       a_speccs,
                       a_chaz,
                       a_scene
                     ] ->
      %{
        uuid: Ecto.UUID.generate(),
        collision_id: nil_or_integer(a_ref),
        year: nil_or_integer(a_year),
        month: nil_or_integer(a_month),
        day: nil_or_integer(a_day),
        hour: nil_or_integer(a_hour),
        min: nil_or_integer(a_min),
        weekday: nil_or_integer(a_wkday),
        district: nil_or_string(a_district),
        grid_ref_1: nil_or_integer(a_gd1),
        grid_ref_2: nil_or_integer(a_gd2),
        junction_detail: nil_or_string(a_jdet),
        junction_control: nil_or_string(a_jcont),
        speed_limit: nil_or_integer(a_speed),
        light_conditions: nil_or_string(a_light),
        weather: nil_or_string(a_weat),
        road_surface: nil_or_string(a_roadsc),
        special_conditions: nil_or_string(a_speccs),
        carriageway_hazards: nil_or_string(a_chaz),
        pedestrian_crossing_human: nil_or_string(a_pedhum),
        pedestrian_crossing_physical: nil_or_string(a_pedphys),
        total_vehicles: nil_or_integer(a_veh),
        total_casualties: nil_or_integer(a_cas),
        collision_type: nil_or_string(a_ctype),
        severity: normalize_severity(a_type),
        police_attended_scene: nil_or_boolean(a_scene),
        inserted_at: {:placeholder, :now},
        updated_at: {:placeholder, :now}
      }
    end)
    |> Stream.chunk_every(@chunk_size)
    |> Enum.each(&insert_collisions(&1))
  end

  defp insert_collisions(collisions_chunk) do
    now = DateTime.utc_now()
    placeholders = %{now: now}

    Repo.insert_all(Schema, collisions_chunk, placeholders: placeholders)
  end

  defp normalize_severity(nil), do: nil

  defp normalize_severity(severity) do
    case severity do
      "Fatal injury collision" -> :fatal
      "Serious injury collision" -> :serious
      "Slight injury collision" -> :slight
      other -> other
    end
  end
end
