import Config

config :digitalocean,
  url: "https://api.digitalocean.com/v2",
  req_options: [plug: {Req.Test, Digitalocean}]
