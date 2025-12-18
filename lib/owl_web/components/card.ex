defmodule OwlWeb.Components.Card do
  @moduledoc false
  use Phoenix.Component

  attr :title, :string, required: true
  attr :value, :any, required: true
  attr :class, :string, default: ""

  def card(assigns) do
    ~H"""
    <div class={[
      "flex flex-col justify-center items-center",
      "w-40 h-40 rounded-xl shadow-md",
      "bg-white border",
      "text-black",
      @class
    ]}>
      <span class="text-sm font-medium">
        {@title}
      </span>

      <span class="text-3xl font-bold mt-2">
        {@value}
      </span>
    </div>
    """
  end
end
