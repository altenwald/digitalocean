defmodule Digitalocean.Client do
  @moduledoc """
  Builds and configures `Req.Request` instances for communicating with the DigitalOcean API v2.
  """

  @default_url "https://api.digitalocean.com/v2"

  @doc """
  Builds a new `Req.Request` client configured with authentication headers and Finch pool.

  ## Parameters
  - `opts_or_token`: Can be a binary token or a keyword list of options:
    - `:token` - DigitalOcean API Bearer token (OAuth access token or Personal Access Token).
    - `:url` - Base API URL (defaults to `https://api.digitalocean.com/v2` or application env).
    - `:req_options` - Additional options passed directly to `Req.new/1`.

  ## Examples

      client = Digitalocean.Client.new("dop_v1_xyz...")
      client = Digitalocean.Client.new(token: "dop_v1_xyz...")
      client = Digitalocean.Client.new() # uses configured application env
  """
  @spec new(String.t() | keyword()) :: Req.Request.t()
  def new(opts_or_token \\ [])

  def new(token) when is_binary(token) do
    new(token: token)
  end

  def new(opts) when is_list(opts) do
    base_url =
      Keyword.get(
        opts,
        :url,
        Application.get_env(:digitalocean, :url, @default_url)
      )

    token =
      Keyword.get(
        opts,
        :token,
        Application.get_env(:digitalocean, :token)
      )

    headers = [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]

    headers =
      if token do
        [{"authorization", "Bearer #{token}"} | headers]
      else
        headers
      end

    custom_req_options =
      Keyword.get(
        opts,
        :req_options,
        Application.get_env(:digitalocean, :req_options, [])
      )

    [
      base_url: base_url,
      headers: headers,
      finch: [name: Digitalocean.Finch],
      retry: false
    ]
    |> Keyword.merge(custom_req_options)
    |> Req.new()
  end
end
