defmodule WS.Client do
  require OpCodes
  import Frames
  import WS

  @mask "1234"
  @host String.to_charlist("localhost")

  @spec connect(char) :: no_return()
  def connect(port) do
    IO.write("channel: ")
    channel = String.trim(IO.read(:stdio, :line))
    opts = [:binary, packet: :raw, active: true]
    {:ok, socket} = :gen_tcp.connect(@host, port, opts)
    :ok = handshake(socket, @host, channel)
    :ok = validate_handshake()

    spawn(fn -> receive_loop(socket) end)
  end

  def input(pid, msg) do
    send(pid, {:input, msg})
  end

  defp receive_loop(socket) do
    receive do
      {:tcp, socket, data} ->
        case parse_unmasked_frame(data) do
          {:text, data} ->
            IO.inspect(data, label: "received data")
          {:close, data} ->
            IO.inspect(data, label: "Received Close")
            send_frame(compose_frame("/close"), socket)
            exit(:close)
          {:ping, data} ->
            IO.inspect(data, label: "Received Ping")
            send_frame(make_masked_frame(data, OpCodes.pong, @mask), socket)
        end
      {:input, data} ->
        data
        |> String.trim()
        |> IO.inspect(label: "sending message")
        |> compose_frame()
        |> send_frame(socket)
    end
    receive_loop(socket)
  end

  defp compose_frame(text) do
    {opcode, msg} =
    case text do
      "/close " <> rest -> {OpCodes.close, rest}
      "/ping " <> rest -> {OpCodes.ping, rest}
      "/bin " <> rest -> {OpCodes.binary, rest}
      _ -> {OpCodes.text, text}
    end
    make_masked_frame(msg, opcode, @mask)
  end

  defp handshake(socket, host, channel), do:
    :gen_tcp.send(socket, WS.Utils.client_handshake(host, channel) |> IO.inspect())

  defp validate_handshake() do
    # TODO: Validate handshake, confirming correctnes of key, etc.
    receive do
      {:tcp, _socket, _handshake} -> :ok
    end
  end

end
