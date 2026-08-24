defmodule Digitalocean.Account do
  @moduledoc """
  Schema and API operations for DigitalOcean User Account information.
  """
  use TypedEctoSchema

  alias Digitalocean.Client
  alias Digitalocean.Common.Error

  @primary_key false

  @typedoc """
  Account information fields:
  - `droplet_limit`: The total number of Droplets current user may create.
  - `floating_ip_limit`: The total number of Floating IPs current user may allocate.
  - `email`: The email address associated with the account.
  - `uuid`: The unique universal identifier for the account.
  - `email_verified`: Whether the account email is verified.
  - `status`: Status of the account (e.g. `"active"`, `"warning"`, `"locked"`).
  - `status_message`: Description of why the account is in a non-active status.
  - `team`: Information about team membership if applicable.
  """
  typed_embedded_schema do
    field(:droplet_limit, :integer)
    field(:floating_ip_limit, :integer)
    field(:email, :string)
    field(:uuid, :string)
    field(:email_verified, :boolean)
    field(:status, :string)
    field(:status_message, :string)

    embeds_one :team, Team, primary_key: false do
      @moduledoc "Team metadata associated with the account."
      field(:uuid, :string)
      field(:name, :string)
    end
  end

  @doc """
  Retrieves account information for the authenticated token.

  ## Examples

      {:ok, %Digitalocean.Account{} = account} = Digitalocean.Account.get(client)
  """
  @spec get(Req.Request.t()) :: {:ok, t()} | {:error, Error.t()}
  def get(client \\ Client.new()) do
    case Req.get(client, url: "/account") do
      {:ok, %{status: 200, body: %{"account" => account_data}}} ->
        {:ok, cast(account_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc false
  @spec cast(map() | nil) :: t() | nil
  def cast(params) when is_map(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(_), do: nil
end
