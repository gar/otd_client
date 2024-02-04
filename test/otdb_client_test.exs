defmodule OTDBClientTest do
  use ExUnit.Case
  doctest OTDBClient

  test "greets the world" do
    assert OTDBClient.hello() == :world
  end
end
