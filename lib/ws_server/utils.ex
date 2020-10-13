defmodule WSServer.Utils do
  @websocket_magic_string "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  # minimal acceptable response
  def handshake_response(%{secret_key: secret_key}), do:
    [
    "HTTP/1.1 101 Switching Protocols\r\n",
    "Upgrade: websocket\r\n",
    "Connection: Upgrade\r\n",
    "Sec-WebSocket-Accept: " <> generate_secret(secret_key) <> "\r\n",
    "\r\n"
    ]


  defp generate_secret(secret_key), do:
    secret_key <> @websocket_magic_string
    |> (&:crypto.hash(:sha, &1)).()
    |> Base.encode64
end
