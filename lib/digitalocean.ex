defmodule Digitalocean do
  @moduledoc """
  DigitalOcean API v2 Client and OAuth integration library for Elixir.

  Supports:
  - Complete OAuth 2.0 flow (`Digitalocean.OAuth`)
  - User Account metadata (`Digitalocean.Account`)
  - Droplets management (`Digitalocean.Droplet`)
  - Projects and Project Resources (`Digitalocean.Project`)
  - Domains and DNS Records (`Digitalocean.Domain`)
  """

  alias Digitalocean.{Account, Client, Domain, Droplet, OAuth, Project}

  @doc """
  Builds a new `Req.Request` client configured for the DigitalOcean API.
  """
  defdelegate client(opts \\ []), to: Client, as: :new

  @doc """
  Generates the OAuth authorization URL.
  """
  defdelegate authorize_url(opts \\ []), to: OAuth

  @doc """
  Exchanges an OAuth authorization code for an access token.
  """
  defdelegate fetch_token(code, opts \\ []), to: OAuth

  @doc """
  Refreshes an OAuth token using a refresh token.
  """
  defdelegate refresh_token(refresh_token, opts \\ []), to: OAuth

  @doc """
  Retrieves account information.
  """
  defdelegate account(client \\ Client.new()), to: Account, as: :get

  @doc """
  Lists droplets.
  """
  defdelegate list_droplets(client \\ Client.new(), params \\ []), to: Droplet, as: :list

  @doc """
  Gets a specific droplet.
  """
  defdelegate get_droplet(client \\ Client.new(), droplet_id), to: Droplet, as: :get

  @doc """
  Lists projects.
  """
  defdelegate list_projects(client \\ Client.new(), params \\ []), to: Project, as: :list

  @doc """
  Gets a project by ID or `"default"`.
  """
  defdelegate get_project(client \\ Client.new(), project_id \\ "default"), to: Project, as: :get

  @doc """
  Lists domains.
  """
  defdelegate list_domains(client \\ Client.new(), params \\ []), to: Domain, as: :list
end
