defmodule Digitalocean.OAuth do
  @moduledoc """
  OAuth 2.0 flow helper for DigitalOcean.

  Provides functions for building the authorization URL, exchanging an authorization
  code for access/refresh tokens, refreshing expired tokens, and revoking tokens.
  """

  alias Digitalocean.Common.Error
  alias Digitalocean.OAuth.Token

  @default_oauth_url "https://cloud.digitalocean.com/v1/oauth"

  @doc """
  Builds the DigitalOcean OAuth authorization URL to redirect users to.

  ## Options
  - `:client_id` - OAuth Client ID (defaults to application env `:oauth_client_id` or `:client_id`).
  - `:redirect_uri` - Callback URL (defaults to application env `:oauth_redirect_uri` or `:redirect_uri`).
  - `:scope` - Scope requested, e.g. `"read"` or `"read write"` (default: `"read write"`).
  - `:state` - CSRF protection state parameter (recommended).
  - `:response_type` - Defaults to `"code"`.
  - `:base_url` - OAuth base URL (defaults to `"https://cloud.digitalocean.com/v1/oauth"`).

  ## Example

      url = Digitalocean.OAuth.authorize_url(
        client_id: "do_client_123",
        redirect_uri: "https://dymmer.com/auth/digitalocean/callback",
        state: "csrf_token_xyz",
        scope: "read write"
      )
  """
  @spec authorize_url(keyword()) :: String.t()
  def authorize_url(opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @default_oauth_url)
    client_id = Keyword.get(opts, :client_id, get_config(:client_id))
    redirect_uri = Keyword.get(opts, :redirect_uri, get_config(:redirect_uri))
    scope = Keyword.get(opts, :scope, "read write")
    state = Keyword.get(opts, :state)
    response_type = Keyword.get(opts, :response_type, "code")

    query_params =
      [
        {"client_id", client_id},
        {"redirect_uri", redirect_uri},
        {"response_type", response_type},
        {"scope", scope},
        {"state", state}
      ]
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> URI.encode_query()

    "#{base_url}/authorize?#{query_params}"
  end

  @doc """
  Exchanges an authorization code for an OAuth access token.

  ## Options
  - `:client_id` - OAuth Client ID.
  - `:client_secret` - OAuth Client Secret.
  - `:redirect_uri` - Callback URL matching authorization request.
  - `:base_url` - OAuth base URL.
  - `:req_options` - Additional options passed to `Req.post/2`.

  ## Example

      {:ok, %Digitalocean.OAuth.Token{} = token} =
        Digitalocean.OAuth.fetch_token("auth_code_from_callback",
          client_id: "...",
          client_secret: "...",
          redirect_uri: "https://dymmer.com/auth/digitalocean/callback"
        )
  """
  @spec fetch_token(String.t(), keyword()) :: {:ok, Token.t()} | {:error, Error.t()}
  def fetch_token(code, opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @default_oauth_url)
    client_id = Keyword.get(opts, :client_id, get_config(:client_id))
    client_secret = Keyword.get(opts, :client_secret, get_config(:client_secret))
    redirect_uri = Keyword.get(opts, :redirect_uri, get_config(:redirect_uri))

    body = %{
      grant_type: "authorization_code",
      code: code,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    }

    post_oauth_token("#{base_url}/token", body, opts)
  end

  @doc """
  Refreshes an existing access token using a refresh token.

  ## Example

      {:ok, %Digitalocean.OAuth.Token{} = new_token} =
        Digitalocean.OAuth.refresh_token("existing_refresh_token",
          client_id: "...",
          client_secret: "..."
        )
  """
  @spec refresh_token(String.t(), keyword()) :: {:ok, Token.t()} | {:error, Error.t()}
  def refresh_token(refresh_token, opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @default_oauth_url)
    client_id = Keyword.get(opts, :client_id, get_config(:client_id))
    client_secret = Keyword.get(opts, :client_secret, get_config(:client_secret))

    body = %{
      grant_type: "refresh_token",
      refresh_token: refresh_token,
      client_id: client_id,
      client_secret: client_secret
    }

    post_oauth_token("#{base_url}/token", body, opts)
  end

  @doc """
  Revokes an OAuth access token or refresh token.

  ## Options
  - `:token_type_hint` - `"access_token"` (default) or `"refresh_token"`.
  - `:base_url` - OAuth base URL.
  """
  @spec revoke_token(String.t(), keyword()) :: :ok | {:error, Error.t()}
  def revoke_token(token, opts \\ []) do
    base_url = Keyword.get(opts, :base_url, @default_oauth_url)
    token_type_hint = Keyword.get(opts, :token_type_hint, "access_token")

    req_options =
      opts
      |> Keyword.get(:req_options, Application.get_env(:digitalocean, :req_options, []))
      |> Keyword.merge(finch: [name: Digitalocean.Finch], retry: false)

    client = Req.new(req_options)

    case Req.post(client,
           url: "#{base_url}/revoke",
           form: [token: token, token_type_hint: token_type_hint]
         ) do
      {:ok, %{status: status}} when status in 200..299 ->
        :ok

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  defp post_oauth_token(url, form_body, opts) do
    req_options =
      opts
      |> Keyword.get(:req_options, Application.get_env(:digitalocean, :req_options, []))
      |> Keyword.merge(finch: [name: Digitalocean.Finch], retry: false)

    client = Req.new(req_options)

    case Req.post(client, url: url, form: form_body) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, Token.cast(body)}

      {:ok, %{body: body}} ->
        {:error, Error.cast(body)}

      {:error, reason} ->
        {:error, Error.cast(reason)}
    end
  end

  defp get_config(key) do
    Application.get_env(:digitalocean, :"oauth_#{key}") ||
      Application.get_env(:digitalocean, key)
  end
end
