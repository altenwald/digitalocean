defmodule Digitalocean.Common.Meta do
  @moduledoc """
  Pagination metadata returned with list requests in the DigitalOcean API.
  """
  use TypedEctoSchema

  @primary_key false

  typed_embedded_schema do
    field(:total, :integer)
  end

  @doc false
  @spec cast(map() | nil) :: t() | nil
  def cast(params) when is_map(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(_), do: nil
end
