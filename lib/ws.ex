defmodule WS do
  require OpCodes

  defmacro __using__(opts) do
    df_parser = Keyword.get(opts, :parser)
    quote do
      def read_dataframes(socket, acc \\ "", opts \\ %{}) do
        WS._read_dataframes(socket, unquote(df_parser), acc, opts)
      end
    end
  end

  def _read_dataframes(socket, parser, acc, opts) do
    with {:ok, data} <- :gen_tcp.recv(socket, 0) do
      case parser.(data) do
        %{fin: 1, opcode: OpCodes.close, data: data} -> {:close, data} # Close. Control frames are never fragmented, so fin=1
        %{fin: 1, opcode: OpCodes.ping, data: data} -> {:ping, data} # Ping.
        %{fin: 1, opcode: OpCodes.pong, data: data} -> {:pong, data} # Pong.
        %{fin: 1, data: data} -> {:ok, acc <> data}
        %{fin: 0, data: data} -> _read_dataframes(socket, parser, acc <> data, opts)
      end
    end
  end

end
