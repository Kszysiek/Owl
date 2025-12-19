defmodule OwlWeb.DashboardLive.Components do
  @moduledoc false
  use Phoenix.Component

  def stat_card(assigns) do
    ~H"""
    <div class="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
      <p class="text-sm font-medium text-slate-500">{@title}</p>
      <p class="text-2xl font-bold text-slate-900 mt-1">{@value}</p>
    </div>
    """
  end

  def collision_details_section(assigns) do
    ~H"""
    <section class="max-w-4xl">
      <h2 class="text-base font-semibold text-slate-900 mb-3">Selected Collision Details</h2>

      <%= if @details do %>
        <div class="rounded-2xl border p-6 shadow-sm bg-gray-50 grid grid-cols-2 lg:grid-cols-4 gap-6">
          <.detail_item label="Date" value={@details.date_time} />
          <.detail_item label="Location" value={@details.location} />
          <.detail_item label="Severity" value={@details.severity} class="capitalize" />
          <.detail_item label="Casualties" value={@details.casualties} />
          <.detail_item label="Weather" value={@details.weather || "N/A"} />
          <.detail_item label="Road Surface" value={@details.road_surface || "N/A"} />
          <.detail_item label="Speed Limit" value={"#{@details.speed_limit} mph"} />
          <div class="col-span-2 lg:col-span-4 border-t pt-4 mt-2">
            <.detail_item label="Vehicles Involved" value={Enum.join(@details.vehicle_types, ", ")} />
          </div>
        </div>
      <% else %>
        <p class="text-sm text-slate-500 italic">
          Click a row in the table above to see detailed information.
        </p>
      <% end %>
    </section>
    """
  end

  defp detail_item(assigns) do
    ~H"""
    <div class={assigns[:class]}>
      <label class="block text-xs font-semibold uppercase tracking-wider text-slate-500">
        {@label}
      </label>
      <div class="mt-1 text-sm font-medium text-slate-900">{@value}</div>
    </div>
    """
  end
end
