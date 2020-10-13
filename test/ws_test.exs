defmodule WSTest do
  use ExUnit.Case
  doctest WS

  test "greets the world" do
    assert WS.hello() == :world
  end
end
