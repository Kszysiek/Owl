defmodule OwlWeb.Live.Dashboard.Resolver do
  @moduledoc false
  alias Owl.Collisions

  # Mapping AgGrid field names to database schema fields
  @grid_to_field %{
    "date" => :date,
    "district" => :district,
    "severity" => :severity,
    "casualties" => :total_casualties,
    "weather" => :weather,
    "road_surface" => :road_surface
  }

  def init_data(params) do
    # Ensure keys are atoms for the context/domain layer
    search_params =
      params
      |> Map.take(["end_year", "fatal", "serious", "slight", "start_year"])
      |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)

    chart_data =
      search_params
      |> Collisions.list_collisions_count_per_month()
      |> Enum.map(&%{month: format_month_year(&1.month), count: &1.count})

    %{
      total_collisions: Collisions.count_collisions(search_params),
      total_casualties: Collisions.calculate_total_casualties(search_params),
      fatal_collisions: Collisions.calculate_fatal_casualties(search_params),
      chart_data: chart_data,
      month_with_most_collisions: find_peak_month(chart_data)
    }
  end

  @doc """
  Directly handles the raw map sent by the AgGrid "get_rows" event.
  """
  def get_paginated_collisions_from_grid(%{
        "start_row" => start,
        "end_row" => stop,
        "sort_model" => sort_model,
        "filters" => filters
      }) do
    sort_config = parse_sort_model(sort_model)

    # Convert string keys to atoms so the Context function can pattern match/use them
    atom_filters =
      for {key, val} <- filters, into: %{} do
        {String.to_existing_atom(key), val}
      end

    Collisions.list_collision_details_paginated(atom_filters, start, stop, sort_config)
  end

  def get_collision_details(uuid), do: Collisions.get_collision_detail(uuid)

  # --- Private Helpers ---

  defp parse_sort_model([%{"colId" => col, "sort" => direction} | _]) do
    case {@grid_to_field[col], direction} do
      {field, "asc"} when not is_nil(field) -> {field, :asc}
      {field, "desc"} when not is_nil(field) -> {field, :desc}
      _ -> nil
    end
  end

  defp parse_sort_model(_), do: nil

  defp find_peak_month([]), do: "N/A"

  defp find_peak_month(chart_data) do
    chart_data
    |> Enum.max_by(& &1.count, fn -> %{month: "N/A"} end)
    |> Map.get(:month)
  end

  defp format_month_year(month_year_str) do
    with [m, y] <- String.split(month_year_str, "-"),
         {month, _} <- Integer.parse(m),
         {:ok, date} <- Date.new(2000, month, 1) do
      "#{Calendar.strftime(date, "%b")}-#{y}"
    else
      _ -> month_year_str
    end
  end
end
