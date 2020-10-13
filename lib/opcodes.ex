defmodule OpCodes do
  defmacro continue(), do: quote do: 0x0
  defmacro text(), do: quote do: 0x1
  defmacro binary(), do: quote do: 0x2
  defmacro close(), do: quote do: 0x8
  defmacro ping(), do: quote do: 0x9
  defmacro pong(), do: quote do: 0xA
end
