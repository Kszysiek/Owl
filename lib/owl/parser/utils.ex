defmodule Owl.Parser.Utils do
  @moduledoc false
  defguardp is_empty_string(value) when value == "" or value == " "

  def nil_or_integer(value) when is_empty_string(value), do: nil

  def nil_or_integer(value) do
    case Integer.parse(value) do
      {number, ""} -> number
      :error -> nil
    end
  end

  def nil_or_string(value) when is_empty_string(value), do: nil
  def nil_or_string(value), do: value

  def nil_or_boolean(value) do
    value
    |> String.downcase()
    |> case do
      "yes" -> true
      "no" -> false
      _ -> nil
    end
  end
end
