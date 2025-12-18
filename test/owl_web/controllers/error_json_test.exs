defmodule OwlWeb.ErrorJSONTest do
  use OwlWeb.ConnCase, async: true

  test "renders 404" do
    assert OwlWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert OwlWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
