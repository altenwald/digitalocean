defmodule Digitalocean.EctoHelpers do
  @moduledoc """
  Ecto Helpers providing common conversion and cleanup functions across schemas.
  """
  import Ecto.Changeset

  @doc """
  Retrieve in plain format the list of errors for a changeset.
  """
  @spec traverse_errors(Ecto.Changeset.t()) :: map()
  def traverse_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Recursively removes `nil` and empty lists from maps.
  """
  @spec clean_data(any()) :: any()
  def clean_data(map) when is_map(map) and not is_struct(map) do
    map
    |> Map.reject(fn {_key, value} -> value in [nil, []] end)
    |> Map.new(fn {key, value} -> {key, clean_data(value)} end)
  end

  def clean_data(list) when is_list(list) do
    list
    |> Enum.reject(&(&1 in [nil, []]))
    |> Enum.map(&clean_data/1)
  end

  def clean_data(otherwise), do: otherwise
end
