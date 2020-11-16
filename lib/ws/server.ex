defmodule WS.Server do
  require OpCodes
  import Frames
  import WS

  @spec accept(char()) :: no_return()
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: true, reuseaddr: true])
    IO.puts("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  # repeatedly accept connections and serve them.
  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(
      WS.Server.TaskSupervisor,
      fn -> serve(client) end
    )
    IO.inspect(pid, label: "starting server process")
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  # reads input from socket and passes it back again
  defp serve(socket) do
    IO.puts("Performing handshake...")
    opts = read_handshake() |> parse_handshake()

    :ok = send_handshake_resp(opts, socket)
    WS.Server.Register.add(opts.channel)

    IO.puts("Entering serve loop...")
    serve_loop(socket, opts.channel)
  end

  defp serve_loop(socket, channel) do
    receive do
      {:internal, data} ->
        send_message(data, socket)
      {:tcp, socket, data} ->
        case parse_masked_frame(data) do
          {:close, data} ->
            IO.inspect(data, label: "Received Close")
            IO.puts("Closing connection...")
            send_close(data, socket)
            exit(:close)
          {:ping, data} ->
            IO.inspect(data, label: "Received Ping")
            IO.puts("Sending Pong...")
            send_message(data, socket, OpCodes.pong)
         {:text, data} ->
            IO.inspect(data, label: "Received and sending")
            send_message(data, socket)
            for pid <- WS.Server.Register.get(channel), pid != self() do
              IO.inspect(pid, label: "sharing msg with")
              send(pid, {:internal, data})
            end
        end
    end
    serve_loop(socket, channel)
  end

  defp send_handshake_resp(opts, socket), do:
    WS.Utils.server_handshake(opts)
    |> (&:gen_tcp.send(socket, &1)).()

  defp parse_handshake(handshake) do
    for line <- String.split(handshake, "\r\n"), into: %{} do
      case line do
        "Sec-WebSocket-Key: " <> key -> {:secret_key, String.trim(key)}
        "GET " <> info -> {:channel, hd String.split(info)}
        _ -> {:nil, nil}
      end
    end
    |> IO.inspect(label: "server got handshake opts")
  end

  defp read_handshake() do
    receive do
      {:tcp, _socket, data} -> data
    end
  end

  defp send_message(msg, socket, opcode \\ 1) do
    IO.inspect(msg, label: "server sending")
    msg |> make_unmasked_frame(opcode) |> send_frame(socket)
  end

  defp send_close({code, _msg}, socket), do:
    send_message(Integer.to_string(code), socket)

end
