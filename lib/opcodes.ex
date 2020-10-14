defmodule OpCodes do
  @atom_map %{
    0x0 => :continue,
    0x1 => :text,
    0x2 => :binary,
    0x8 => :close,
    0x9 => :ping,
    0xA => :pong
  }
  defmacro continue(), do: quote do: 0x0
  defmacro text(), do: quote do: 0x1
  defmacro binary(), do: quote do: 0x2
  defmacro close(), do: quote do: 0x8
  defmacro ping(), do: quote do: 0x9
  defmacro pong(), do: quote do: 0xA
  def atomize(code) do
    Map.get(@atom_map, code)
  end
end
