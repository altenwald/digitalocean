# Digitalocean

DigitalOcean API v2 Client and OAuth integration library in Elixir.

## Features

- **OAuth 2.0 Flow**: Complete integration (`authorize_url`, code exchange, refresh token, revocation).
- **Modern HTTP Client**: Powered by `Req` and `Finch` with connection pooling and fast in-process testing via `Req.Test`.
- **Typed Data Structures**: Built with `typed_ecto_schema` and `Ecto.embedded_load/3` for type safety.
- **Resource Management**:
  - `Digitalocean.Account` (Account information, team, droplet/IP limits)
  - `Digitalocean.Project` (Projects and resource assignments)
  - `Digitalocean.Droplet` (Droplets, sizes, images, networks)
  - `Digitalocean.Domain` (Domains and DNS records)

---

## Installation

Add `digitalocean` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:digitalocean, "~> 0.1.0"}
  ]
end
```

---

## Usage

### 1. OAuth 2.0 Flow

#### Generating Authorization URL
```elixir
url = Digitalocean.authorize_url(
  client_id: "your_oauth_client_id",
  redirect_uri: "https://example.com/auth/digitalocean/callback",
  state: "csrf_token_xyz",
  scope: "read write"
)

# Redirect the user to `url`
```

#### Exchanging Code for Access Token
```elixir
{:ok, %Digitalocean.OAuth.Token{} = token} =
  Digitalocean.fetch_token(code,
    client_id: "your_oauth_client_id",
    client_secret: "your_oauth_client_secret",
    redirect_uri: "https://example.com/auth/digitalocean/callback"
  )

# Access token properties:
# token.access_token
# token.refresh_token
# token.expires_in
# token.info.email
```

#### Refreshing Expired Token
```elixir
{:ok, %Digitalocean.OAuth.Token{} = new_token} =
  Digitalocean.refresh_token(token.refresh_token,
    client_id: "your_oauth_client_id",
    client_secret: "your_oauth_client_secret"
  )
```

---

### 2. Direct Resource Access

```elixir
client = Digitalocean.client("dop_v1_...")

# Account
{:ok, account} = Digitalocean.Account.get(client)

# Droplets
{:ok, droplets, meta} = Digitalocean.Droplet.list(client)
{:ok, droplet} = Digitalocean.Droplet.get(client, 123456)

# Projects
{:ok, projects, meta} = Digitalocean.Project.list(client)
{:ok, resources, _} = Digitalocean.Project.list_resources(client, "default")

# Domains & DNS
{:ok, domains, _} = Digitalocean.Domain.list(client)
{:ok, records, _} = Digitalocean.Domain.list_records(client, "example.com")
```

---

## Testing

Testing is fully supported without external network access using `Req.Test`:

```bash
mix test
```
