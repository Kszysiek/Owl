defmodule Owl.Collisions do
  @moduledoc false
  import Ecto.Query

  alias Owl.Collisions.Schema
  alias Owl.Repo
  alias Owl.VehiclesDate

  def list, do: Repo.all(Schema)

  def list_uuids_by_collision_id_and_year(collision_ids, years) do
    Schema
    |> where([s], s.collision_id in ^collision_ids)
    |> where([s], s.year in ^years)
    |> select([s], %{collision_id: s.collision_id, year: s.year, uuid: s.uuid})
    |> Repo.all()
    |> Map.new(&{{&1.collision_id, &1.year}, &1.uuid})
  end

  def calculate_total_collisions(%{
        fatal: fatal,
        serious: serious,
        slight: slight,
        start_year: start_year,
        end_year: end_year
      }),
      do:
        Schema
        |> filter_by_year(start_year, end_year)
        |> maybe_filter_by_severity(fatal, serious, slight)
        |> Repo.aggregate(:count)

  def calculate_total_casualties(%{
        fatal: fatal,
        serious: serious,
        slight: slight,
        start_year: start_year,
        end_year: end_year
      }),
      do:
        Schema
        |> filter_by_year(start_year, end_year)
        |> maybe_filter_by_severity(fatal, serious, slight)
        |> Repo.aggregate(:sum, :total_casualties)

  def calculate_fatal_casualties(%{start_year: start_year, end_year: end_year}),
    do: Schema |> filter_by_year(start_year, end_year) |> where([s], s.severity == :fatal) |> Repo.aggregate(:count)

  def count_collisions(%{fatal: fatal, serious: serious, slight: slight, start_year: start_year, end_year: end_year}) do
    Schema
    |> filter_by_year(start_year, end_year)
    |> maybe_filter_by_severity(fatal, serious, slight)
    |> Repo.aggregate(:count)
  end

  def list_collisions_count_per_month(%{
        fatal: fatal,
        serious: serious,
        slight: slight,
        start_year: start_year,
        end_year: end_year
      }) do
    Schema
    |> group_by([s], [s.month, s.year])
    |> filter_by_year(start_year, end_year)
    |> maybe_filter_by_severity(fatal, serious, slight)
    |> select([s], %{month: fragment("? || '-' || ?", s.month, s.year), count: count(s.uuid)})
    |> order_by([s], {:asc, [s.year, s.month]})
    |> Repo.all()
  end

  def list_collision_details(%{
        fatal: fatal,
        serious: serious,
        slight: slight,
        start_year: start_year,
        end_year: end_year
      }) do
    Schema
    |> filter_by_year(start_year, end_year)
    |> maybe_filter_by_severity(fatal, serious, slight)
    |> select([s], %{
      uuid: s.uuid,
      date: s.day,
      district: s.district,
      severity: s.severity,
      casualties: s.total_casualties,
      weather: s.weather,
      road_surface: s.road_surface
    })
    |> Repo.all()
  end

  def list_collision_details_paginated(
        %{fatal: fatal, serious: serious, slight: slight, start_year: start_year, end_year: end_year},
        start_row,
        end_row,
        sort_model
      ) do
    query =
      Schema
      |> filter_by_year(start_year, end_year)
      |> maybe_filter_by_severity(fatal, serious, slight)

    total_count = Repo.aggregate(query, :count)

    limit_value = end_row - start_row

    row_data =
      query
      |> select([s], %{
        uuid: s.uuid,
        date:
          fragment(
            "make_timestamptz(?, ?, ?, ?, ?, 0)",
            s.year,
            s.month,
            s.day,
            s.hour,
            s.min
          ),
        district: s.district,
        severity: s.severity,
        casualties: s.total_casualties,
        weather: s.weather,
        road_surface: s.road_surface
      })
      |> limit(^limit_value)
      |> offset(^start_row)
      |> maybe_order_by_field(sort_model)
      |> Repo.all()

    %{row_data: row_data, row_count: total_count}
  end

  def get_collision_detail(collision_uuid) do
    Schema
    |> where([s], s.uuid == ^collision_uuid)
    |> select([s, vd, vi], %{
      datetime:
        fragment(
          "make_timestamptz(?, ?, ?, ?, ?, 0)",
          s.year,
          s.month,
          s.day,
          s.hour,
          s.min
        ),
      district: s.district,
      severity: s.severity,
      casualties: s.total_casualties,
      weather: s.weather,
      road_surface: s.road_surface,
      light_conditions: s.light_conditions,
      speed_limit: s.speed_limit,
      year: s.year
    })
    |> Repo.one()
    |> case do
      nil ->
        nil

      record ->
        vehicle_types = VehiclesDate.list_vehicle_types_with_collision_id(collision_uuid, record.year)
        format_collision_detail(record, vehicle_types)
    end
  end

  defp filter_by_year(query, start_year, end_year) do
    year_list = get_year_list(start_year, end_year)
    where(query, [s], s.year in ^year_list)
  end

  defp get_year_list(start_year, end_year) do
    start_year = if is_binary(start_year), do: String.to_integer(start_year), else: start_year
    end_year = if is_binary(end_year), do: String.to_integer(end_year), else: end_year
    Enum.to_list(start_year..end_year)
  end

  defp maybe_filter_by_severity(query, fatal?, serious?, slight?) do
    [
      {fatal?, :fatal},
      {serious?, :serious},
      {slight?, :slight}
    ]
    |> Enum.filter(fn {enabled, _severity} -> enabled end)
    |> Enum.map(fn {_enabled, severity} -> severity end)
    |> case do
      [] ->
        query

      selected_severities ->
        where(query, [s], s.severity in ^selected_severities)
    end
  end

  defp format_collision_detail(record, vehicle_types) do
    %{
      date_time: Calendar.strftime(record.datetime, "%Y-%m-%d %H:%M"),
      location: record.district,
      severity: record.severity,
      casualties: record.casualties,
      weather: record.weather,
      road_surface: record.road_surface,
      light_conditions: record.light_conditions,
      speed_limit: record.speed_limit,
      vehicle_types: vehicle_types
    }
  end

  defp maybe_order_by_field(query, nil), do: query

  defp maybe_order_by_field(query, {:date, sort_type}) do
    from s in query,
      order_by: [
        {^sort_type,
         fragment(
           "make_timestamptz(?, ?, ?, ?, ?, 0)",
           s.year,
           s.month,
           s.day,
           s.hour,
           s.min
         )}
      ]
  end

  defp maybe_order_by_field(query, {field, sort_type}) when is_atom(field) do
    from s in query,
      order_by: [{^sort_type, field(s, ^field)}]
  end
end
