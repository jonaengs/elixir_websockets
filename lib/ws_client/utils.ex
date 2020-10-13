defmodule WSClient.Utils do
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

end
