defmodule Digitalocean.Application do
  @moduledoc false
  use Application

  @doc false
  def start(_type, _args) do
    children = [
      {Finch, name: Digitalocean.Finch}
    ]

    opts = [strategy: :one_for_one, name: Digitalocean.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
