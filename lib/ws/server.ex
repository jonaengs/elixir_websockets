defmodule WS.Server do
  require OpCodes
  import Frames
  alias WS.Utils
  use WS, [parser: &parse_masked_frame/2, timeout: 120_000]

  @num_retries 10

  @spec accept(char()) :: no_return()
  def accept(port) do
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :raw, active: false, reuseaddr: true])
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
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  # reads input from socket and passes it back again
  defp serve(socket) do
    IO.puts("Performing handshake...")
    socket
    |> read_handshake
    |> parse_handshake()
    |> send_handshake_resp(socket)

    IO.puts("Entering serve loop...")
    serve_loop(socket)
  end

  defp serve_loop(socket, consecutive_ping_count \\ 0)
  defp serve_loop(socket, consec_ping_c) when consec_ping_c >= @num_retries, do:
    send_close({1001, ""}, socket)
  defp serve_loop(socket, consec_ping_c) do
    case read_frames(socket) do
      {:close, data} ->
        IO.inspect(data, label: "Received Close")
        IO.puts("Closing connection...")
        send_close(data, socket)
      {:ping, data} ->
        IO.inspect(data, label: "Received Ping")
        IO.puts("Sending Pong...")
        send_message(data, socket, OpCodes.pong)
        serve_loop(socket)
      {:ok, data} ->
        IO.inspect(data, label: "Received and sending")
        send_message(data, socket)
        serve_loop(socket)
      {:error, :timeout} ->
        IO.puts("Timed out. Performing ping...")
        case ping(socket) do
          {true, true} -> serve_loop(socket)
          {false, _} ->
            IO.puts("Performed ping without response. Trying again: \##{consec_ping_c}")
            serve_loop(socket, consec_ping_c + 1)
        end
    end
  end

  defp send_handshake_resp(opts, socket), do:
    :ok =
    Utils.server_handshake(opts)
    |> Enum.join()
    |> (&:gen_tcp.send(socket, &1)).()

  '''
  Performs a ping and listens for a response.
  Returns a pair of booleans indicating:
  1. response received within timeout limit
  2. message data matches what was sent
  '''
  defp ping(socket, msg \\ "") do
    :ok = send_message(msg, socket, OpCodes.ping)
    case read_frames(socket) do
      {:pong, data} -> {true, data == msg}
      {:error, :timeout} -> {false, false}
    end
  end

  defp parse_handshake(handshake), do:
    Enum.reduce(String.split(handshake, "\r\n"), %{},
      fn line, opts ->
        case line do
          "Sec-WebSocket-Key: " <> key -> Map.put(opts, :secret_key, String.trim(key))
          _ -> opts
        end
      end
    )

  defp read_handshake(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp send_message(msg, socket, opcode \\ 1) do
    IO.inspect(msg, label: "server sending")
    msg |> make_unmasked_frame(opcode) |> send_frame(socket)
  end

  defp send_close({code, _msg}, socket), do:
    send_message(Integer.to_string(code), socket)

end
