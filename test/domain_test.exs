defmodule Digitalocean.DomainTest do
  use ExUnit.Case, async: true

  alias Digitalocean.{Client, Domain}

  describe "domains and records" do
    test "lists domains" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v2/domains"

        Req.Test.json(conn, %{
          "domains" => [
            %{"name" => "example.com", "ttl" => 1800, "zone_file" => "..."}
          ],
          "meta" => %{"total" => 1}
        })
      end)

      client = Client.new("test_token")
      assert {:ok, [domain], _meta} = Domain.list(client)
      assert domain.name == "example.com"
      assert domain.ttl == 1800
    end

    test "lists and creates records" do
      Req.Test.stub(Digitalocean, fn conn ->
        case {conn.method, conn.request_path} do
          {"GET", "/v2/domains/example.com/records"} ->
            Req.Test.json(conn, %{
              "domain_records" => [
                %{
                  "id" => 123,
                  "type" => "A",
                  "name" => "@",
                  "data" => "198.51.100.10",
                  "ttl" => 1800
                }
              ],
              "meta" => %{"total" => 1}
            })

          {"POST", "/v2/domains/example.com/records"} ->
            conn
            |> Plug.Conn.put_status(201)
            |> Req.Test.json(%{
              "domain_record" => %{
                "id" => 124,
                "type" => "CNAME",
                "name" => "www",
                "data" => "@",
                "ttl" => 1800
              }
            })
        end
      end)

      client = Client.new("test_token")
      assert {:ok, [record], _meta} = Domain.list_records(client, "example.com")
      assert record.id == 123
      assert record.type == "A"
      assert record.data == "198.51.100.10"

      assert {:ok, new_rec} =
               Domain.create_record(client, "example.com", %{
                 type: "CNAME",
                 name: "www",
                 data: "@"
               })

      assert new_rec.id == 124
      assert new_rec.type == "CNAME"
    end
  end
end
