defmodule WSClient do
  require OpCodes
  alias WSClient.Utils
  import DataFrames

  @mask "1234"

  @spec connect(binary, char) :: no_return()
  def connect(host, port) do
    opts = [:binary, packet: :raw, active: false]
    {:ok, socket} = :gen_tcp.connect(String.to_charlist(host), port, opts)
    :ok = handshake(socket, host)
    :ok = validate_handshake(socket)
    send_recv_loop(socket)
  end

  defp send_recv_loop(socket) do
    msg = String.trim(IO.read(:stdio, :line))
    df = make_client_dataframe(msg, OpCodes.text, @mask)
    IO.inspect(msg, label: "got msg")
    IO.inspect(df, label: "Sending df")
    send_dataframe(df, socket)
    read_dataframes(socket) |> IO.inspect(label: "Received data")
    send_recv_loop(socket)
  end

  defp handshake(socket, host, subdir \\ ""), do:
    :gen_tcp.send(socket, Utils.client_handshake(host, subdir) |> IO.inspect())

  defp validate_handshake(socket) do
    # TODO: Validate handshake, confirming correctnes of key, etc.
    _handshake = :gen_tcp.recv(socket, 0)
    :ok
  end

  defp send_dataframe(dataframe, socket), do:
    :ok = :gen_tcp.send(socket, dataframe)

  def read_dataframes(socket, _opts \\ %{}, acc \\ "") do
    with {:ok, data} <- :gen_tcp.recv(socket, 0) do
      case parse_server_dataframe(data) do
        %{fin: 1, opcode: OpCodes.close, data: data} -> {:close, data} # Close. Control frames are never fragmented, so fin=1
        %{fin: 1, opcode: OpCodes.ping, data: data} -> {:ping, data} # Ping.
        %{fin: 1, opcode: OpCodes.pong, data: data} -> {:pong, data} # Pong.
        %{fin: 1, data: data} -> {:ok, acc <> data}
        %{fin: 0, data: data} -> read_dataframes(socket, acc <> data)
      end
    end
  end

end
