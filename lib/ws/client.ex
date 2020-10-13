defmodule WS.Client do
  require OpCodes
  alias WS.Utils
  import DataFrames
  import WS
  use WS, parser: &parse_unmasked_dataframe/1

  @mask "1234"

  @spec connect(binary, char) :: no_return()
  def connect(host, port) do
    opts = [:binary, packet: :raw, active: false]
    {:ok, socket} = :gen_tcp.connect(String.to_charlist(host), port, opts)
    :ok = handshake(socket, host)
    :ok = validate_handshake(socket)
    {:ok, recv_pid} = Task.Supervisor.start_child(
      WS.Client.TaskSupervisor,
      fn -> receive_loop(socket) end
    )
    IO.inspect(recv_pid, label: "recv child")
    read_send_loop(socket)
  end

  defp receive_loop(socket) do
    # TODO: handle all received cases
    case read_dataframes(socket) do
      {:ok, data} ->
        IO.inspect(data, label: "received data")
        receive_loop(socket)
      {:close, data} ->
        IO.inspect(data, label: "Received Close")
        send_close(data, socket)
      {:ping, data} ->
        IO.inspect(data, label: "Received Ping")
        send_dataframe(make_masked_dataframe(data, OpCodes.pong, @mask), socket)
        receive_loop(socket)
    end
  end

  defp read_send_loop(socket) do
    IO.read(:stdio, :line)
    |> String.trim()
    |> IO.inspect(label: "sending message")
    |> compose_dataframe()
    |> send_dataframe(socket)

    read_send_loop(socket)
  end

  defp send_close({code, _msg}, socket) do
    IO.puts("client closing")
    Integer.to_string(code) |> make_masked_dataframe(OpCodes.close, @mask) |> send_dataframe(socket)
  end

  defp compose_dataframe(text) do
    {opcode, msg} =
    case text do
      "/close" <> rest -> {OpCodes.close, rest}
      "/ping" <> rest -> {OpCodes.ping, rest}
      "/bin" <> rest -> {OpCodes.binary, rest}
      _ -> {OpCodes.text, text}
    end
    make_masked_dataframe(msg, opcode, @mask)
  end

  defp handshake(socket, host, subdir \\ ""), do:
    :gen_tcp.send(socket, Utils.client_handshake(host, subdir) |> IO.inspect())

  defp validate_handshake(socket) do
    # TODO: Validate handshake, confirming correctnes of key, etc.
    {:ok, _handshake} = :gen_tcp.recv(socket, 0)
    :ok
  end
end
