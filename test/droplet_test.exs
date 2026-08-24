defmodule Digitalocean.DropletTest do
  use ExUnit.Case, async: true

  alias Digitalocean.{Client, Droplet}

  describe "list/2" do
    test "lists droplets and returns parsed struct" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v2/droplets"

        Req.Test.json(conn, %{
          "droplets" => [
            %{
              "id" => 3_164_444,
              "name" => "example.com",
              "memory" => 1024,
              "vcpus" => 1,
              "disk" => 25,
              "status" => "active",
              "size_slug" => "s-1vcpu-1gb",
              "tags" => ["web", "prod"],
              "image" => %{
                "id" => 6_374_128,
                "name" => "22.04 (LTS) x64",
                "distribution" => "Ubuntu"
              },
              "region" => %{
                "name" => "New York 3",
                "slug" => "nyc3"
              },
              "networks" => %{
                "v4" => [
                  %{
                    "ip_address" => "198.51.100.10",
                    "netmask" => "255.255.240.0",
                    "gateway" => "198.51.100.1",
                    "type" => "public"
                  },
                  %{
                    "ip_address" => "10.132.0.5",
                    "netmask" => "255.255.0.0",
                    "gateway" => "10.132.0.1",
                    "type" => "private"
                  }
                ],
                "v6" => []
              }
            }
          ],
          "meta" => %{"total" => 1}
        })
      end)

      client = Client.new("test_token")
      assert {:ok, [droplet], meta} = Droplet.list(client)
      assert droplet.id == 3_164_444
      assert droplet.name == "example.com"
      assert droplet.vcpus == 1
      assert droplet.memory == 1024
      assert droplet.status == "active"
      assert droplet.image.distribution == "Ubuntu"
      assert droplet.region.slug == "nyc3"
      assert meta.total == 1

      assert Droplet.public_ipv4(droplet) == "198.51.100.10"
      assert Droplet.ip_addresses(droplet) == ["198.51.100.10", "10.132.0.5"]
    end
  end

  describe "get/2" do
    test "retrieves a single droplet" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v2/droplets/3164444"

        Req.Test.json(conn, %{
          "droplet" => %{
            "id" => 3_164_444,
            "name" => "example.com",
            "memory" => 2048,
            "vcpus" => 2,
            "disk" => 50,
            "status" => "active"
          }
        })
      end)

      client = Client.new("test_token")
      assert {:ok, %Droplet{} = droplet} = Droplet.get(client, 3_164_444)
      assert droplet.id == 3_164_444
      assert droplet.memory == 2048
      assert droplet.vcpus == 2
    end
  end

  describe "create/2 and delete/2" do
    test "creates droplet" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v2/droplets"

        conn
        |> Plug.Conn.put_status(202)
        |> Req.Test.json(%{
          "droplet" => %{
            "id" => 99_999,
            "name" => "new-host",
            "memory" => 1024,
            "vcpus" => 1,
            "disk" => 25,
            "status" => "new"
          }
        })
      end)

      client = Client.new("test_token")

      assert {:ok, %Droplet{} = droplet} =
               Droplet.create(client, %{
                 name: "new-host",
                 region: "nyc3",
                 size: "s-1vcpu-1gb",
                 image: "ubuntu-22-04-x64"
               })

      assert droplet.id == 99_999
      assert droplet.status == "new"
    end

    test "deletes droplet" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.method == "DELETE"
        assert conn.request_path == "/v2/droplets/99999"
        Plug.Conn.send_resp(conn, 204, "")
      end)

      client = Client.new("test_token")
      assert :ok = Droplet.delete(client, 99_999)
    end
  end
end
