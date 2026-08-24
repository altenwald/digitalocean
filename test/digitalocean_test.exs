defmodule DigitaloceanTest do
  use ExUnit.Case
  doctest Digitalocean

  test "greets the world" do
    assert Digitalocean.hello() == :world
  end
end
