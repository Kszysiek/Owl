defmodule OwlWeb.PageController do
  use OwlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
