defmodule Digitalocean.OAuthTest do
  use ExUnit.Case, async: true

  alias Digitalocean.OAuth
  alias Digitalocean.OAuth.Token

  describe "authorize_url/1" do
    test "generates authorization URL with query parameters" do
      url =
        OAuth.authorize_url(
          client_id: "test_client_id",
          redirect_uri: "https://dymmer.com/auth/callback",
          state: "csrf_state_123",
          scope: "read write"
        )

      uri = URI.parse(url)
      assert uri.scheme == "https"
      assert uri.host == "cloud.digitalocean.com"
      assert uri.path == "/v1/oauth/authorize"

      query = URI.decode_query(uri.query)
      assert query["client_id"] == "test_client_id"
      assert query["redirect_uri"] == "https://dymmer.com/auth/callback"
      assert query["state"] == "csrf_state_123"
      assert query["scope"] == "read write"
      assert query["response_type"] == "code"
    end
  end

  describe "fetch_token/2" do
    test "successfully exchanges code for token" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/v1/oauth/token"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)

        assert params["grant_type"] == "authorization_code"
        assert params["code"] == "test_code_123"
        assert params["client_id"] == "my_client_id"
        assert params["client_secret"] == "my_secret"
        assert params["redirect_uri"] == "https://dymmer.com/auth/callback"

        Req.Test.json(conn, %{
          "access_token" => "dop_v1_access_token_123",
          "token_type" => "Bearer",
          "expires_in" => 2_592_000,
          "refresh_token" => "refresh_token_456",
          "scope" => "read write",
          "uid" => 98_765,
          "info" => %{
            "name" => "Manuel Rubio",
            "email" => "manuel@example.com",
            "uuid" => "user-uuid-123"
          }
        })
      end)

      assert {:ok, %Token{} = token} =
               OAuth.fetch_token("test_code_123",
                 client_id: "my_client_id",
                 client_secret: "my_secret",
                 redirect_uri: "https://dymmer.com/auth/callback",
                 req_options: [plug: {Req.Test, Digitalocean}]
               )

      assert token.access_token == "dop_v1_access_token_123"
      assert token.token_type == "Bearer"
      assert token.expires_in == 2_592_000
      assert token.refresh_token == "refresh_token_456"
      assert token.scope == "read write"
      assert token.uid == 98_765
      assert token.info.name == "Manuel Rubio"
      assert token.info.email == "manuel@example.com"
      assert token.info.uuid == "user-uuid-123"
    end

    test "handles error response" do
      Req.Test.stub(Digitalocean, fn conn ->
        conn
        |> Plug.Conn.put_status(401)
        |> Req.Test.json(%{
          "id" => "unauthorized",
          "message" => "Invalid client credentials"
        })
      end)

      assert {:error, error} =
               OAuth.fetch_token("bad_code",
                 client_id: "bad_id",
                 client_secret: "bad_secret",
                 req_options: [plug: {Req.Test, Digitalocean}]
               )

      assert error.id == "unauthorized"
      assert error.message == "Invalid client credentials"
    end
  end

  describe "refresh_token/2" do
    test "refreshes expired access token" do
      Req.Test.stub(Digitalocean, fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        params = URI.decode_query(body)

        assert params["grant_type"] == "refresh_token"
        assert params["refresh_token"] == "existing_refresh_token"

        Req.Test.json(conn, %{
          "access_token" => "new_access_token_789",
          "token_type" => "Bearer",
          "expires_in" => 2_592_000,
          "refresh_token" => "new_refresh_token_999",
          "scope" => "read write"
        })
      end)

      assert {:ok, %Token{} = token} =
               OAuth.refresh_token("existing_refresh_token",
                 client_id: "my_id",
                 client_secret: "my_secret",
                 req_options: [plug: {Req.Test, Digitalocean}]
               )

      assert token.access_token == "new_access_token_789"
      assert token.refresh_token == "new_refresh_token_999"
    end
  end

  describe "revoke_token/2" do
    test "revokes token" do
      Req.Test.stub(Digitalocean, fn conn ->
        assert conn.request_path == "/v1/oauth/revoke"
        Plug.Conn.send_resp(conn, 200, "")
      end)

      assert :ok =
               OAuth.revoke_token("token_to_revoke",
                 req_options: [plug: {Req.Test, Digitalocean}]
               )
    end
  end
end
