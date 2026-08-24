defmodule Digitalocean.OAuth.Token do
  @moduledoc """
  Schema representing an OAuth token response from DigitalOcean.
  """
  use TypedEctoSchema

  @primary_key false

  typed_embedded_schema do
    field(:access_token, :string)
    field(:token_type, :string, default: "Bearer")
    field(:expires_in, :integer)
    field(:refresh_token, :string)
    field(:scope, :string)
    field(:uid, :integer)

    embeds_one :info, AccountInfo, primary_key: false do
      @moduledoc "Basic account information attached to the OAuth token."
      field(:name, :string)
      field(:email, :string)
      field(:uuid, :string)
    end
  end

  @doc false
  @spec cast(map() | nil) :: t() | nil
  def cast(params) when is_map(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(_), do: nil
end
