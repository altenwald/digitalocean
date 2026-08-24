defmodule DigitaloceanTest do
  use ExUnit.Case, async: true

  test "authorize_url/1 delegates to OAuth" do
    url = Digitalocean.authorize_url(client_id: "test", redirect_uri: "http://localhost")
    assert url =~ "https://cloud.digitalocean.com/v1/oauth/authorize"
  end

  test "client/1 builds Req.Request" do
    client = Digitalocean.client("test_token")
    assert %Req.Request{} = client
  end
end
