defmodule Digitalocean.Project do
  @moduledoc """
  Schema and API operations for DigitalOcean Projects and Project Resources.
  """
  use TypedEctoSchema

  alias Digitalocean.Client
  alias Digitalocean.Common.{Error, Meta}

  @primary_key false

  typed_embedded_schema do
    field(:id, :string, primary_key: true)
    field(:owner_uuid, :string)
    field(:owner_id, :integer)
    field(:name, :string)
    field(:description, :string)
    field(:purpose, :string)
    field(:environment, :string)
    field(:is_default, :boolean)
    field(:created_at, :string)
    field(:updated_at, :string)
  end

  defmodule Resource do
    @moduledoc """
    Schema representing a resource (e.g. Droplet, Domain, Volume) assigned to a DigitalOcean Project.
    """
    use TypedEctoSchema

    @primary_key false

    typed_embedded_schema do
      field(:urn, :string, primary_key: true)
      field(:assigned_at, :string)
      field(:status, :string)
    end

    @doc """
    Extracts the resource type and ID from a URN string (e.g. `"do:droplet:12345"` -> `{:droplet, "12345"}`).
    """
    @spec parse_urn(String.t() | t()) :: {:ok, atom(), String.t()} | :error
    def parse_urn(%__MODULE__{urn: urn}), do: parse_urn(urn)

    def parse_urn(urn) when is_binary(urn) do
      case String.split(urn, ":", parts: 3) do
        ["do", type, id] -> {:ok, String.to_atom(type), id}
        _ -> :error
      end
    end

    @doc false
    @spec cast(map() | nil) :: t() | nil
    def cast(params) when is_map(params) do
      Ecto.embedded_load(__MODULE__, params, :json)
    end

    def cast(_), do: nil
  end

  @doc """
  Lists all projects for the authenticated account.

  ## Examples

      {:ok, projects, meta} = Digitalocean.Project.list(client)
  """
  @spec list(Req.Request.t(), keyword()) :: {:ok, [t()], Meta.t() | nil} | {:error, Error.t()}
  def list(client \\ Client.new(), params \\ []) do
    case Req.get(client, url: "/projects", params: params) do
      {:ok, %{status: 200, body: %{"projects" => projects} = body}} ->
        items = Enum.map(projects, &cast/1)
        meta = Meta.cast(Map.get(body, "meta"))
        {:ok, items, meta}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Retrieves a project by its ID or the default project with `"default"`.

  ## Examples

      {:ok, %Digitalocean.Project{} = project} = Digitalocean.Project.get(client, "default")
      {:ok, %Digitalocean.Project{} = project} = Digitalocean.Project.get(client, "4e16734e-...")
  """
  @spec get(Req.Request.t(), String.t()) :: {:ok, t()} | {:error, Error.t()}
  def get(client \\ Client.new(), project_id \\ "default") do
    case Req.get(client, url: "/projects/#{project_id}") do
      {:ok, %{status: 200, body: %{"project" => project_data}}} ->
        {:ok, cast(project_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Creates a new project.

  ## Examples

      {:ok, project} = Digitalocean.Project.create(client, %{
        name: "My Web App",
        description: "Production project",
        purpose: "Web Application",
        environment: "Production"
      })
  """
  @spec create(Req.Request.t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def create(client \\ Client.new(), params) do
    case Req.post(client, url: "/projects", json: params) do
      {:ok, %{status: 201, body: %{"project" => project_data}}} ->
        {:ok, cast(project_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Updates an existing project.
  """
  @spec update(Req.Request.t(), String.t(), map()) :: {:ok, t()} | {:error, Error.t()}
  def update(client \\ Client.new(), project_id, params) do
    case Req.put(client, url: "/projects/#{project_id}", json: params) do
      {:ok, %{status: 200, body: %{"project" => project_data}}} ->
        {:ok, cast(project_data)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Deletes a project by its ID.
  """
  @spec delete(Req.Request.t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(client \\ Client.new(), project_id) do
    case Req.delete(client, url: "/projects/#{project_id}") do
      {:ok, %{status: 204}} ->
        :ok

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Lists all resources assigned to a project.

  ## Examples

      {:ok, resources, meta} = Digitalocean.Project.list_resources(client, "default")
  """
  @spec list_resources(Req.Request.t(), String.t(), keyword()) ::
          {:ok, [Resource.t()], Meta.t() | nil} | {:error, Error.t()}
  def list_resources(client \\ Client.new(), project_id \\ "default", params \\ []) do
    case Req.get(client, url: "/projects/#{project_id}/resources", params: params) do
      {:ok, %{status: 200, body: %{"resources" => resources} = body}} ->
        items = Enum.map(resources, &Resource.cast/1)
        meta = Meta.cast(Map.get(body, "meta"))
        {:ok, items, meta}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  @doc """
  Assigns a list of resource URNs to a project.

  ## Examples

      {:ok, resources} = Digitalocean.Project.assign_resources(client, "default", [
        "do:droplet:123456",
        "do:domain:example.com"
      ])
  """
  @spec assign_resources(Req.Request.t(), String.t(), [String.t()]) ::
          {:ok, [Resource.t()]} | {:error, Error.t()}
  def assign_resources(client \\ Client.new(), project_id \\ "default", resources)
      when is_list(resources) do
    case Req.post(client, url: "/projects/#{project_id}/resources", json: %{resources: resources}) do
      {:ok, %{status: 200, body: %{"resources" => res_list}}} ->
        {:ok, Enum.map(res_list, &Resource.cast/1)}

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
