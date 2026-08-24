defmodule Digitalocean.Droplet do
  @moduledoc """
  Schema and API operations for DigitalOcean Droplets (Virtual Machines/Hosts).
  """
  use TypedEctoSchema

  alias Digitalocean.Client
  alias Digitalocean.Common.{Error, Meta}

  @primary_key false

  typed_embedded_schema do
    field(:id, :integer, primary_key: true)
    field(:name, :string)
    field(:memory, :integer)
    field(:vcpus, :integer)
    field(:disk, :integer)
    field(:locked, :boolean)
    field(:status, :string)
    field(:created_at, :string)
    field(:features, {:array, :string}, default: [])
    field(:backup_ids, {:array, :integer}, default: [])
    field(:snapshot_ids, {:array, :integer}, default: [])
    field(:volume_ids, {:array, :string}, default: [])
    field(:size_slug, :string)
    field(:tags, {:array, :string}, default: [])
    field(:vpc_uuid, :string)

    embeds_one :image, Image, primary_key: false do
      @moduledoc "Image/Operating System information."
      field(:id, :integer)
      field(:name, :string)
      field(:distribution, :string)
      field(:slug, :string)
      field(:public, :boolean)
      field(:min_disk_size, :integer)
      field(:type, :string)
      field(:description, :string)
      field(:status, :string)
    end

    embeds_one :size, Size, primary_key: false do
      @moduledoc "Size specifications and pricing details."
      field(:slug, :string)
      field(:memory, :integer)
      field(:vcpus, :integer)
      field(:disk, :integer)
      field(:transfer, :float)
      field(:price_monthly, :float)
      field(:price_hourly, :float)
      field(:available, :boolean)
    end

    embeds_one :region, Region, primary_key: false do
      @moduledoc "Datacenter region where the Droplet resides."
      field(:name, :string)
      field(:slug, :string)
      field(:features, {:array, :string}, default: [])
      field(:available, :boolean)
    end

    embeds_one :networks, Networks, primary_key: false do
      @moduledoc "Network interfaces allocated to the Droplet."

      embeds_many :v4, NetworkV4, primary_key: false do
        @moduledoc "IPv4 network configuration."
        field(:ip_address, :string)
        field(:netmask, :string)
        field(:gateway, :string)
        field(:type, :string)
      end

      embeds_many :v6, NetworkV6, primary_key: false do
        @moduledoc "IPv6 network configuration."
        field(:ip_address, :string)
        field(:netmask, :integer)
        field(:gateway, :string)
        field(:type, :string)
      end
    end
  end

  @doc """
  Lists all Droplets for the authenticated account.

  ## Parameters
  - `client`: `Req.Request` client.
  - `params`: Query parameters such as `page`, `per_page`, `tag_name`.

  ## Examples

      {:ok, droplets, meta} = Digitalocean.Droplet.list(client, per_page: 50)
  """
  @spec list(Req.Request.t(), keyword()) :: {:ok, [t()], Meta.t() | nil} | {:error, Error.t()}
  def list(client \\ Client.new(), params \\ []) do
    case Req.get(client, url: "/droplets", params: params) do
      {:ok, %{status: 200, body: %{"droplets" => droplets} = body}} ->
        items = Enum.map(droplets, &cast/1)
        meta = Meta.cast(Map.get(body, "meta"))
        {:ok, items, meta}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Retrieves a single Droplet by its ID.

  ## Examples

      {:ok, %Digitalocean.Droplet{} = droplet} = Digitalocean.Droplet.get(client, 123456)
  """
  @spec get(Req.Request.t(), integer() | String.t()) :: {:ok, t()} | {:error, Error.t()}
  def get(client \\ Client.new(), droplet_id) do
    case Req.get(client, url: "/droplets/#{droplet_id}") do
      {:ok, %{status: 200, body: %{"droplet" => droplet_data}}} ->
        {:ok, cast(droplet_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Creates a new Droplet.

  ## Examples

      {:ok, droplet} = Digitalocean.Droplet.create(client, %{
        name: "example.com",
        region: "nyc3",
        size: "s-1vcpu-1gb",
        image: "ubuntu-22-04-x64"
      })
  """
  @spec create(Req.Request.t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def create(client \\ Client.new(), params) do
    case Req.post(client, url: "/droplets", json: params) do
      {:ok, %{status: 202, body: %{"droplet" => droplet_data}}} ->
        {:ok, cast(droplet_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Deletes a Droplet by its ID.
  """
  @spec delete(Req.Request.t(), integer() | String.t()) :: :ok | {:error, Error.t()}
  def delete(client \\ Client.new(), droplet_id) do
    case Req.delete(client, url: "/droplets/#{droplet_id}") do
      {:ok, %{status: 204}} ->
        :ok

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Extracts all IP addresses (IPv4 and IPv6, public and private) from a Droplet struct.
  """
  @spec ip_addresses(t()) :: [String.t()]
  def ip_addresses(%__MODULE__{networks: nil}), do: []

  def ip_addresses(%__MODULE__{networks: %{v4: v4, v6: v6}}) do
    ips_v4 = Enum.map(v4 || [], & &1.ip_address)
    ips_v6 = Enum.map(v6 || [], & &1.ip_address)
    Enum.reject(ips_v4 ++ ips_v6, &is_nil/1)
  end

  @doc """
  Retrieves the public IPv4 address of the Droplet, if present.
  """
  @spec public_ipv4(t()) :: String.t() | nil
  def public_ipv4(%__MODULE__{networks: nil}), do: nil

  def public_ipv4(%__MODULE__{networks: %{v4: v4}}) do
    case Enum.find(v4 || [], &(&1.type == "public")) do
      %{ip_address: ip} -> ip
      _ -> nil
    end
  end

  @doc false
  @spec cast(map() | nil) :: t() | nil
  def cast(params) when is_map(params) do
    Ecto.embedded_load(__MODULE__, params, :json)
  end

  def cast(_), do: nil
end
