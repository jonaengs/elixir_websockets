defmodule WS do
  require OpCodes

  @moduledoc """
  About the websockets protocol:
  Websockets is basically a thin layer over tcp that allows for quick communication.
  It is initiated over http, and requires a handshake to be made before the websockets connection
  can be established. The client initiates the handshake and the server responds to that handshake.
  If the handshake goes well, the parts can start communicating over websockets.

  Websocket messages are sent as frames.
  A frame consists of a small header and a payload containing the actual message.
  The header is at least two bytes long - see Frames module for specifics.

  The server sends unmasked frames and the client sends masked frames.

  Reference: https://tools.ietf.org/html/rfc6455
  """

  @doc """
  Setup read_frames function for caller that uses specified
  frame parser and timeout limit
  """

  def send_frame(frame, socket), do: :gen_tcp.send(socket, frame)

end
