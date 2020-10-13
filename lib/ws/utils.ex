defmodule WS.Utils do
  @websocket_magic_string "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  def client_handshake(host, subdirectory), do:
    [
      "GET /#{subdirectory} HTTP/1.1\r\n",
      "Host: #{host}\r\n",
      "Upgrade: websocket\r\n",
      "Connection: Upgrade\r\n",
      "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n",
      "Sec-WebSocket-Version: 13\r\n",
      "\r\n"
    ]
    |> Enum.join()
    |> String.to_charlist()

  # minimal acceptable response
  def server_handshake(%{secret_key: secret_key}), do:
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
