defmodule WS.Client do
  require OpCodes
  alias WS.Utils
  import DataFrames
  import WS
  use WS, parser: &parse_server_dataframe/1

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
    IO.read(:stdio, :line)
    |> String.trim()
    |> IO.inspect(label: "sending message")
    |> make_client_dataframe(OpCodes.text, @mask)
    |> send_dataframe(socket)

    inspect(read_dataframes(socket), label: "Received data")
    send_recv_loop(socket)
  end

  defp handshake(socket, host, subdir \\ ""), do:
    :gen_tcp.send(socket, Utils.client_handshake(host, subdir) |> IO.inspect())

  defp validate_handshake(socket) do
    # TODO: Validate handshake, confirming correctnes of key, etc.
    _handshake = :gen_tcp.recv(socket, 0)
    :ok
  end

end
