defmodule OwlWeb.Live.Dashboard.Resolver do
  @moduledoc false
  alias Owl.Collisions

  def init_data(params) do
    params = %{
      end_year: params["end_year"],
      fatal: params["fatal"],
      serious: params["serious"],
      slight: params["slight"],
      start_year: params["start_year"]
    }

    total_collisions = Collisions.count_collisions(params)
    total_casualties = Collisions.calculate_total_casualties(params)
    fatal_collisions = Collisions.calculate_fatal_casualties(params)

    chart_data =
      params
      |> Collisions.list_collisions_count_per_month()
      |> Enum.map(&%{month: get_month_short_name(&1.month), count: &1.count})

    month_with_most_collisions = get_month_with_most_collisions(chart_data)

    %{
      total_collisions: total_collisions,
      total_casualties: total_casualties,
      fatal_collisions: fatal_collisions,
      chart_data: chart_data,
      month_with_most_collisions: month_with_most_collisions
    }
  end

  def get_paginated_collisions(params, start_row, end_row, sort_model) do
    Collisions.list_collision_details_paginated(params, start_row, end_row, sort_model)
  end

  def get_collision_details(collision_uuid) do
    Collisions.get_collision_detail(collision_uuid)
  end

  defp get_month_with_most_collisions(chart_data) do
    chart_data
    |> Enum.sort_by(& &1.count, :desc)
    |> List.first(%{})
    |> Map.get(:month, "")
  end

  defp get_month_short_name(month_with_year_string) do
    [month, year] = String.split(month_with_year_string, "-")

    date = Date.new!(2000, String.to_integer(month), 1)
    month_name = Calendar.strftime(date, "%b")

    "#{month_name}-#{year}"
  end
end
