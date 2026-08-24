defmodule Digitalocean.Common.Error do
  @moduledoc """
  Represents error responses returned by the DigitalOcean API.
  """
  use TypedEctoSchema

  @primary_key false

  @typedoc """
  DigitalOcean error fields:
  - `id`: Error code identifier (e.g. `"not_found"`, `"unauthorized"`, `"unprocessable_entity"`).
  - `message`: Human-readable error description.
  - `request_id`: Unique request identifier useful for debugging.
  """
  typed_embedded_schema do
    field(:id, :string)
    field(:message, :string)
    field(:request_id, :string)
  end

  @doc false
  @spec cast(any()) :: t()
  def cast(params) when is_map(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(binary) when is_binary(binary) do
    case Jason.decode(binary) do
      {:ok, map} when is_map(map) -> cast(map)
      _ -> %__MODULE__{id: "error", message: binary}
    end
  end

  def cast(other) do
    %__MODULE__{id: "unknown_error", message: inspect(other)}
  end
end
