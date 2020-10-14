defmodule WS.Client do
  require OpCodes
  alias WS.Utils
  import Frames
  use WS, parser: &parse_unmasked_frame/2

  @mask "1234"

  @spec connect(binary, char) :: no_return()
  def connect(host, port) do
    # IO.write("subdomain: ")
    # subdomain = "/" <> String.trim(IO.read(:stdio, :line))
    url = String.to_charlist(host) |> IO.inspect(label: "url")
    opts = [:binary, packet: :raw, active: false]
    {:ok, socket} = :gen_tcp.connect(url, port, opts)
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
    case read_frames(socket) do
      {:ok, data} ->
        IO.inspect(data, label: "received data")
        receive_loop(socket)
      {:close, data} ->
        IO.inspect(data, label: "Received Close")
        send_close(data, socket)
      {:ping, data} ->
        IO.inspect(data, label: "Received Ping")
        send_frame(make_masked_frame(data, OpCodes.pong, @mask), socket)
        receive_loop(socket)
    end
  end

  defp read_send_loop(socket) do
    IO.read(:stdio, :line)
    |> String.trim()
    |> IO.inspect(label: "sending message")
    |> compose_frame()
    |> send_frame(socket)

    read_send_loop(socket)
  end

  defp send_close({code, _msg}, socket) do
    IO.puts("client closing")
    Integer.to_string(code) |> make_masked_frame(OpCodes.close, @mask) |> send_frame(socket)
  end

  defp compose_frame(text) do
    {opcode, msg} =
    case text do
      "/close" <> rest -> {OpCodes.close, rest}
      "/ping" <> rest -> {OpCodes.ping, rest}
      "/bin" <> rest -> {OpCodes.binary, rest}
      _ -> {OpCodes.text, text}
    end
    make_masked_frame(msg, opcode, @mask)
  end

  defp handshake(socket, host, subdir \\ ""), do:
    :gen_tcp.send(socket, Utils.client_handshake(host, subdir) |> IO.inspect())

  defp validate_handshake(socket) do
    # TODO: Validate handshake, confirming correctnes of key, etc.
    {:ok, _handshake} = :gen_tcp.recv(socket, 0)
    :ok
  end
end
