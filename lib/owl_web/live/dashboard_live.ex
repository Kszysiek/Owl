defmodule OwlWeb.DashboardLive do
  @moduledoc false
  use OwlWeb, :live_view

  import OwlWeb.DashboardLive.Components

  alias OwlWeb.Live.Dashboard.Resolver

  @initial_data %{
    total_collisions: 0,
    total_casualties: 0,
    fatal_collisions: 0,
    month_with_most_collisions: "Loading..."
  }

  @form_defaults %{
    "fatal" => true,
    "serious" => true,
    "slight" => true,
    "start_year" => 2021,
    "end_year" => 2022
  }

  @grid_config %{
    cols: [
      %{field: "date", headerName: "Date", type: ["dateFormatter"]},
      %{field: "district", headerName: "District"},
      %{field: "severity", headerName: "Severity"},
      %{field: "casualties", headerName: "Casualties"},
      %{field: "weather", headerName: "Weather", type: ["maybe_empty"]},
      %{field: "road_surface", headerName: "Road Surface", type: ["maybe_empty"]}
    ],
    def: %{filter: true, sortable: true}
  }

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:year_range, 2017..2022)
      |> assign(:collision_details, nil)
      |> assign(:selected_uuid, nil)

    if connected?(socket) do
      data = Resolver.init_data(@form_defaults)

      {:ok,
       socket
       |> assign_data(data)
       |> assign_form(@form_defaults)
       |> push_initial_data(data)}
    else
      {:ok,
       socket
       |> assign(@initial_data)
       |> assign_form(@form_defaults)}
    end
  end

  def handle_event("update_filters", %{"filters" => params}, socket) do
    # Normalize types from form strings
    filters = %{
      "fatal" => params["fatal"] == "true",
      "serious" => params["serious"] == "true",
      "slight" => params["slight"] == "true",
      "start_year" => String.to_integer(params["start_year"]),
      "end_year" => String.to_integer(params["end_year"])
    }

    data = Resolver.init_data(filters)

    {:noreply,
     socket
     |> assign_data(data)
     |> assign_form(filters)
     |> push_event("update_chart", %{data: data.chart_data})
     |> push_event("update_grid", %{filters: filters})}
  end

  def handle_event("row-selected", %{"uuid" => uuid}, socket) do
    details = Resolver.get_collision_details(uuid)
    {:noreply, assign(socket, selected_uuid: uuid, collision_details: details)}
  end

  def handle_event("get_rows", params, socket) do
    # Delegate formatting logic to the Resolver to keep LV clean
    result = Resolver.get_paginated_collisions_from_grid(params)
    {:reply, %{row_data: result.row_data, row_count: result.row_count}, socket}
  end

  # Helpers
  defp assign_data(socket, data) do
    assign(socket,
      total_collisions: data.total_collisions,
      total_casualties: data.total_casualties,
      fatal_collisions: data.fatal_collisions,
      month_with_most_collisions: data.month_with_most_collisions
    )
  end

  defp assign_form(socket, params), do: assign(socket, :form, to_form(params, as: :filters))

  defp push_initial_data(socket, data) do
    socket
    |> push_event("load_chart", %{data: data.chart_data})
    |> push_event("load_grid", %{
      gridDefs: @grid_config.cols,
      defaultColDef: @grid_config.def,
      filters: @form_defaults
    })
  end
end
