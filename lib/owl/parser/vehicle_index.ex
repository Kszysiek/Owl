defmodule Owl.Parser.VehicleIndex do
  @moduledoc false

  alias Owl.Repo
  alias Owl.VehiclesIndex.Schema

  @priv_dir "priv"
  @chunk_size 1000

  def parse(path) do
    :owl
    |> Application.app_dir(@priv_dir)
    |> Path.join(path)
    |> File.stream!()
    |> Owl.Parser.CsvParser.parse_stream(skip_headers: true)
    |> Stream.map(fn [col, dummy, name] ->
      %{
        col: col,
        code: parse_to_integer(dummy),
        name: name,
        inserted_at: {:placeholder, :now},
        updated_at: {:placeholder, :now}
      }
    end)
    |> Stream.chunk_every(@chunk_size)
    |> Enum.each(&insert_vehicles(&1))
  end

  defp insert_vehicles(chunk) do
    now = DateTime.utc_now()
    placeholders = %{now: now}

    Repo.insert_all(Schema, chunk, placeholders: placeholders)
  end

  defp parse_to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      :error -> nil
    end
  end
end
