defmodule Digitalocean.AccountTest do
  use ExUnit.Case, async: true

  alias Digitalocean.{Account, Client}

  describe "get/1" do
    test "fetches account details" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.method == "GET"
        assert conn.request_path == "/v2/account"

        Req.Test.json(conn, %{
          "account" => %{
            "droplet_limit" => 25,
            "floating_ip_limit" => 5,
            "email" => "sammy@digitalocean.com",
            "uuid" => "6303f1a6-account-uuid",
            "email_verified" => true,
            "status" => "active",
            "status_message" => "",
            "team" => %{
              "uuid" => "team-uuid-1",
              "name" => "Dymmer Team"
            }
          }
        })
      end)

      client = Client.new("test_token")
      assert {:ok, %Account{} = account} = Account.get(client)
      assert account.email == "sammy@digitalocean.com"
      assert account.droplet_limit == 25
      assert account.status == "active"
      assert account.team.name == "Dymmer Team"
    end
  end
end
