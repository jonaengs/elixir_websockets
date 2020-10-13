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
    read_dataframes(socket, &parse_server_dataframe/1) |> IO.inspect(label: "Received data")
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

end
