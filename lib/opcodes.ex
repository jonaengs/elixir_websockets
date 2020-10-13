defmodule OpCodes do
  defmacro continue() do
    quote do: 0x0
  end
  defmacro text() do
    quote do: 0x1
  end
  defmacro binary() do
    quote do: 0x2
  end
  defmacro close() do
    quote do: 0x8
  end
  defmacro ping() do
    quote do: 0x9
  end
  defmacro pong() do
    quote do: 0xA
  end
end
