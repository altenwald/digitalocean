defmodule Digitalocean.Domain do
  @moduledoc """
  Schema and API operations for DigitalOcean Domains and DNS Records.
  """
  use TypedEctoSchema

  alias Digitalocean.Client
  alias Digitalocean.Common.{Error, Meta}

  @primary_key false

  typed_embedded_schema do
    field(:name, :string, primary_key: true)
    field(:ttl, :integer)
    field(:zone_file, :string)
  end

  defmodule Record do
    @moduledoc """
    Schema for individual DNS Records within a DigitalOcean domain.
    """
    use TypedEctoSchema

    @primary_key false

    typed_embedded_schema do
      field(:id, :integer, primary_key: true)
      field(:type, :string)
      field(:name, :string)
      field(:data, :string)
      field(:priority, :integer)
      field(:port, :integer)
      field(:ttl, :integer)
      field(:weight, :integer)
      field(:flags, :integer)
      field(:tag, :string)
    end

    @doc false
    @spec cast(map() | nil) :: t() | nil
    def cast(params) when is_map(params) do
      Ecto.embedded_load(__MODULE__, params, :json)
    end

    def cast(_), do: nil
  end

  @doc """
  Lists all domains registered in DigitalOcean.
  """
  @spec list(Req.Request.t(), keyword()) :: {:ok, [t()], Meta.t() | nil} | {:error, Error.t()}
  def list(client \\ Client.new(), params \\ []) do
    case Req.get(client, url: "/domains", params: params) do
      {:ok, %{status: 200, body: %{"domains" => domains} = body}} ->
        items = Enum.map(domains, &cast/1)
        meta = Meta.cast(Map.get(body, "meta"))
        {:ok, items, meta}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Retrieves a single domain by its name.
  """
  @spec get(Req.Request.t(), String.t()) :: {:ok, t()} | {:error, Error.t()}
  def get(client \\ Client.new(), domain_name) do
    case Req.get(client, url: "/domains/#{domain_name}") do
      {:ok, %{status: 200, body: %{"domain" => domain_data}}} ->
        {:ok, cast(domain_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Creates a new domain in DigitalOcean.
  """
  @spec create(Req.Request.t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def create(client \\ Client.new(), params) do
    case Req.post(client, url: "/domains", json: params) do
      {:ok, %{status: 201, body: %{"domain" => domain_data}}} ->
        {:ok, cast(domain_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Deletes a domain by its name.
  """
  @spec delete(Req.Request.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(client \\ Client.new(), domain_name) do
    case Req.delete(client, url: "/domains/#{domain_name}") do
      {:ok, %{status: 204}} ->
        :ok

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Lists DNS records for a domain.
  """
  @spec list_records(Req.Request.t(), String.t(), keyword()) ::
          {:ok, [Record.t()], Meta.t() | nil} | {:error, Error.t()}
  def list_records(client \\ Client.new(), domain_name, params \\ []) do
    case Req.get(client, url: "/domains/#{domain_name}/records", params: params) do
      {:ok, %{status: 200, body: %{"domain_records" => records} = body}} ->
        items = Enum.map(records, &Record.cast/1)
        meta = Meta.cast(Map.get(body, "meta"))
        {:ok, items, meta}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Retrieves a specific DNS record.
  """
  @spec get_record(Req.Request.t(), String.t(), integer() | String.t()) ::
          {:ok, Record.t()} | {:error, Error.t()}
  def get_record(client \\ Client.new(), domain_name, record_id) do
    case Req.get(client, url: "/domains/#{domain_name}/records/#{record_id}") do
      {:ok, %{status: 200, body: %{"domain_record" => record_data}}} ->
        {:ok, Record.cast(record_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Creates a new DNS record under a domain.
  """
  @spec create_record(Req.Request.t(), String.t(), map()) ::
          {:ok, Record.t()} | {:error, Error.t()}
  def create_record(client \\ Client.new(), domain_name, params) do
    case Req.post(client, url: "/domains/#{domain_name}/records", json: params) do
      {:ok, %{status: 201, body: %{"domain_record" => record_data}}} ->
        {:ok, Record.cast(record_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Updates an existing DNS record.
  """
  @spec update_record(Req.Request.t(), String.t(), integer() | String.t(), map()) ::
          {:ok, Record.t()} | {:error, Error.t()}
  def update_record(client \\ Client.new(), domain_name, record_id, params) do
    case Req.put(client, url: "/domains/#{domain_name}/records/#{record_id}", json: params) do
      {:ok, %{status: 200, body: %{"domain_record" => record_data}}} ->
        {:ok, Record.cast(record_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Deletes a DNS record.
  """
  @spec delete_record(Req.Request.t(), String.t(), integer() | String.t()) ::
          :ok | {:error, Error.t()}
  def delete_record(client \\ Client.new(), domain_name, record_id) do
    case Req.delete(client, url: "/domains/#{domain_name}/records/#{record_id}") do
      {:ok, %{status: 204}} ->
        :ok

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
