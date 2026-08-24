defmodule Digitalocean.ProjectTest do
  use ExUnit.Case, async: true

  alias Digitalocean.{Client, Project}

  describe "list/2 and get/2" do
    test "lists projects" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v2/projects"

        Req.Test.json(conn, %{
          "projects" => [
            %{
              "id" => "4e16734e-1234-5678",
              "name" => "Production App",
              "description" => "Dymmer cluster",
              "purpose" => "Web Application",
              "environment" => "Production",
              "is_default" => true
            }
          ],
          "meta" => %{"total" => 1}
        })
      end)

      client = Client.new("test_token")
      assert {:ok, [project], meta} = Project.list(client)
      assert project.name == "Production App"
      assert project.environment == "Production"
      assert project.is_default == true
      assert meta.total == 1
    end

    test "gets project by id" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v2/projects/4e16734e-1234-5678"

        Req.Test.json(conn, %{
          "project" => %{
            "id" => "4e16734e-1234-5678",
            "name" => "Production App",
            "is_default" => true
          }
        })
      end)

      client = Client.new("test_token")
      assert {:ok, %Project{} = project} = Project.get(client, "4e16734e-1234-5678")
      assert project.id == "4e16734e-1234-5678"
    end
  end

  describe "resources" do
    test "lists project resources and parses URNs" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v2/projects/default/resources"

        Req.Test.json(conn, %{
          "resources" => [
            %{
              "urn" => "do:droplet:3164444",
              "assigned_at" => "2023-01-01T00:00:00Z",
              "status" => "ok"
            },
            %{
              "urn" => "do:domain:example.com",
              "assigned_at" => "2023-01-01T00:00:00Z",
              "status" => "ok"
            }
          ],
          "meta" => %{"total" => 2}
        })
      end)

      client = Client.new("test_token")
      assert {:ok, [res1, res2], meta} = Project.list_resources(client, "default")
      assert res1.urn == "do:droplet:3164444"
      assert Project.Resource.parse_urn(res1) == {:ok, :droplet, "3164444"}
      assert res2.urn == "do:domain:example.com"
      assert Project.Resource.parse_urn(res2) == {:ok, :domain, "example.com"}
      assert meta.total == 2
    end

    test "assigns resources to project" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v2/projects/default/resources"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body) == %{"resources" => ["do:droplet:3164444"]}

        Req.Test.json(conn, %{
          "resources" => [
            %{
              "urn" => "do:droplet:3164444",
              "assigned_at" => "2023-01-01T00:00:00Z",
              "status" => "ok"
            }
          ]
        })
      end)

      client = Client.new("test_token")

      assert {:ok, [res]} =
               Project.assign_resources(client, "default", ["do:droplet:3164444"])

      assert res.urn == "do:droplet:3164444"
    end
  end
end
