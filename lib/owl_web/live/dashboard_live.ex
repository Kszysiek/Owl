defmodule OwlWeb.DashboardLive do
  @moduledoc false
  use OwlWeb, :live_view

  alias OwlWeb.Live.Dashboard.Resolver

  @initial_data %{
    total_collisions: 0,
    total_casualties: 0,
    fatal_collisions: 0,
    chart_data: [],
    month_with_most_collisions: ""
  }

  @form_initial_data %{
    "fatal" => true,
    "serious" => true,
    "slight" => true,
    "start_year" => 2021,
    "end_year" => 2022
  }

  @collision_records_columns [
    %{field: "date", headerName: "Date", type: ["dateFormatter"]},
    %{field: "district", headerName: "District"},
    %{field: "severity", headerName: "Severity"},
    %{field: "casualties", headerName: "Casualties"},
    %{field: "weather", headerName: "Weather", type: ["maybeEmptyFormatter"]},
    %{field: "road_surface", headerName: "Road Surface", type: ["maybeEmptyFormatter"]}
  ]

  @collisions_columns_to_field %{
    "date" => :date,
    "district" => :district,
    "severity" => :severity,
    "casualties" => :total_casualties,
    "weather" => :weather,
    "road_surface" => :road_surface
  }

  @defaultColDef %{
    filter: true,
    sortable: true
  }

  @start_and_end_year_range 2017..2022

  def mount(_params, _session, socket) do
    params =
      if connected?(socket) do
        Resolver.init_data(@form_initial_data)
      else
        @initial_data
      end

    socket =
      if connected?(socket) do
        socket
        |> push_event("load_chart", %{data: params.chart_data})
        |> push_event("load_grid", %{
          gridDefs: @collision_records_columns,
          defaultColDef: @defaultColDef,
          filters: @form_initial_data
        })
        |> assign(
          total_collisions: params.total_collisions,
          total_casualties: params.total_casualties,
          fatal_collisions: params.fatal_collisions,
          month_with_most_collisions: params.month_with_most_collisions,
          start_and_end_year_range: @start_and_end_year_range,
          form: to_form(@form_initial_data, as: :filters),
          collision_details: nil
        )
      else
        assign(socket,
          total_collisions: params.total_collisions,
          total_casualties: params.total_casualties,
          fatal_collisions: params.fatal_collisions,
          month_with_most_collisions: params.month_with_most_collisions,
          start_and_end_year_range: @start_and_end_year_range,
          form: to_form(@form_initial_data, as: :filters),
          collision_details: nil
        )
      end

    {:ok, socket}
  end

  def handle_event(
        "update_filters",
        %{
          "filters" => %{
            "start_year" => start_year,
            "end_year" => end_year,
            "fatal" => fatal,
            "serious" => serious,
            "slight" => slight
          }
        },
        socket
      ) do
    start_year = String.to_integer(start_year)
    end_year = String.to_integer(end_year)

    form = %{
      "fatal" => fatal == "true",
      "serious" => serious == "true",
      "slight" => slight == "true",
      "start_year" => start_year,
      "end_year" => end_year
    }

    data = Resolver.init_data(form)

    {:noreply,
     socket
     |> push_event("update_chart", %{data: data.chart_data})
     |> push_event("update_grid", %{filters: form})
     |> assign(
       form: to_form(form, as: :filters),
       total_collisions: data.total_collisions,
       total_casualties: data.total_casualties,
       fatal_collisions: data.fatal_collisions,
       month_with_most_collisions: data.month_with_most_collisions
     )}
  end

  def handle_event("row-selected", %{"uuid" => uuid}, socket) do
    collision_details = Resolver.get_collision_details(uuid)
    {:noreply, assign(socket, selected_collision_uuid: uuid, collision_details: collision_details)}
  end

  def handle_event(
        "get_rows",
        %{"start_row" => start_row, "end_row" => end_row, "sort_model" => sort_model, "filters" => filters},
        socket
      ) do
    sort_model = format_sort_model(sort_model)

    result =
      Resolver.get_paginated_collisions(
        %{
          end_year: filters["end_year"],
          fatal: filters["fatal"],
          serious: filters["serious"],
          slight: filters["slight"],
          start_year: filters["start_year"]
        },
        start_row,
        end_row,
        sort_model
      )

    {:reply, %{row_data: result.row_data, row_count: result.row_count}, socket}
  end

  defp format_sort_model([]), do: nil

  defp format_sort_model([%{"colId" => column_name, "sort" => sort_type}]) do
    case {@collisions_columns_to_field[column_name], format_sort_type(sort_type)} do
      {nil, _sort_type} -> nil
      {_field, nil} -> nil
      {field, sort_type} -> {field, sort_type}
    end
  end

  defp format_sort_type("asc"), do: :asc
  defp format_sort_type("desc"), do: :desc
  defp format_sort_type(_other), do: nil

  defp format_nullable_field(nil), do: "N/A"
  defp format_nullable_field(value), do: value

  defp join_with_comma(value) when is_list(value), do: Enum.join(value, ", ")
  defp join_with_comma(value), do: value

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-7xl px-4 sm:px-6 lg:px-8 py-6 space-y-8">
        <.form
          for={@form}
          id="filters"
          phx-change="update_filters"
          class="flex flex-col justify-center md:flex-row md:items-center md:justify-end gap-4 p-4 rounded-xl"
        >
          <div class="flex flex-wrap gap-4 items-center">
            <.input
              type="checkbox"
              field={@form[:fatal]}
              label="Fatal"
              inner_label_checkbox_class="flex items-center"
            />
            <.input
              type="checkbox"
              field={@form[:serious]}
              label="Serious"
              inner_label_checkbox_class="flex items-center"
            />
            <.input
              type="checkbox"
              field={@form[:slight]}
              label="Slight"
              inner_label_checkbox_class="flex items-center"
            />
          </div>

          <div class="flex gap-4">
            <.input
              type="select"
              field={@form[:start_year]}
              options={Enum.map(@start_and_end_year_range, &{"#{&1}", &1})}
              label="Start year"
              inner_label_select_class="flex gap-2"
            />
            <.input
              type="select"
              field={@form[:end_year]}
              options={Enum.map(@start_and_end_year_range, &{"#{&1}", &1})}
              label="End year"
              inner_label_select_class="flex gap-2"
            />
          </div>
        </.form>

        <div class="grid grid-cols-1 justify-items-center sm:grid-cols-2 lg:grid-cols-4 gap-4 md:gap-6 lg:gap-8">
          <.card title="Total Collisions" value={@total_collisions} />
          <.card title="Total Casualties" value={@total_casualties} />
          <.card title="Fatal Collisions" value={@fatal_collisions} />
          <.card title="Most dangerous month" value={@month_with_most_collisions} />
        </div>

        <div
          id="collisions_chart"
          phx-hook="AgChart"
          phx-update="ignore"
          class="w-full h-[400px] rounded-xl shadow-sm"
        >
        </div>

        <div class="overflow-hidden rounded-xl shadow-sm">
          <div
            id="collision_records"
            phx-hook="AgGrid"
            phx-update="ignore"
            class="w-full h-[500px]"
          >
          </div>
        </div>

        <section class="max-w-4xl">
          <h2 class="text-base font-semibold text-slate-900 mb-3">
            Selected Collision Details
          </h2>

          <p :if={!@collision_details} class="text-sm text-slate-500 italic">
            Click a row in the table above to see detailed information.
          </p>

          <div
            :if={@collision_details}
            class="rounded-2xl border p-6 shadow-sm bg-gray-300"
          >
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-y-8 gap-x-12 ">
              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Date
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {@collision_details.date_time}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Location
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {@collision_details.location}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Severity
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900 capitalize">
                  {@collision_details.severity}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Casualties
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {@collision_details.casualties}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Weather
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {format_nullable_field(@collision_details.weather)}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Road Surface
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {format_nullable_field(@collision_details.road_surface)}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Light Conditions
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {format_nullable_field(@collision_details.light_conditions)}
                </div>
              </div>

              <div>
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Speed Limit
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {@collision_details.speed_limit} mph
                </div>
              </div>

              <div class="col-span-2 lg:col-span-4 pt-4">
                <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
                  Vehicles Involved
                </label>
                <div class="mt-1 text-sm font-medium text-slate-900">
                  {join_with_comma(@collision_details.vehicle_types)}
                </div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </Layouts.app>
    """
  end
end
