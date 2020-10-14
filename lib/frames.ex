defmodule Frames do
  require OpCodes

  @max_uint_16 65536

  @moduledoc """

  Frame format: (adapted from https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API/Writing_WebSocket_servers)
  0               1               2               3
  0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7
  +-+-+-+-+-------+-+-------------+-------------------------------+
  |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
  |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
  |N|V|V|V|       |S|             |   (if payload len==126/127)   |
  | |1|2|3|       |K|             |                               |
  +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
  |     Extended payload length continued, if payload len == 127  |
  + - - - - - - - - - - - - - - - +-------------------------------+
  |                               |Masking-key, if MASK set to 1  |
  +-------------------------------+-------------------------------+
  | Masking-key (continued)       |          Payload Data         |
  +-------------------------------- - - - - - - - - - - - - - - - +
  :                     Payload Data continued ...                :
  + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
  |                     Payload Data continued ...                |
  +---------------------------------------------------------------+

  * fin = final frame of the message?
  * rsv = extra bits that must be negotiated. Always 0 here.
  * opcode = Operation type (text, ping, close, ...)
    * For multi-frame messages, the first frame specifies the operation and the remaining use 0x0 (cont.)
    * Op types 0-2 are for sending data. These frames are therefore called data frames
    * Op types 8-10 are for communication control. These frames are therefore called control frames
      * Control frames MUST have a payload length lte 125 and cannot be fragmented.
      * Control frames can be injected in the middle of a fragmented message. THIS IS NOT HANDLED AT THE MOMENT.
  * mask = payload is masked? Frames from client MUST be masked. Frames from server must NOT be masked
  * payload len = length of payload. 126 or 127 => next 16 or 64 bytes specify length, respectively.
    * This parameter is not useful in the current application, so it is simply removed
  * payload is either text or binary, as specified by opcodes 0x1 (text) and 0x2 (binary)
  * When opcode is 8 (close), the first 16 bits of the message are an unsigned int = closing code.
  Read more: https://tools.ietf.org/html/rfc6455
  """
  def parse_masked_frame(<<fin::1, 0::3, opcode::4, 1::1, paylen::7>> <> rest, _opts \\ %{}) do
    <<mask::32>> <> payload = strip_paylen_bits(paylen, rest)
    mask = <<mask::32>>
    data = case opcode do
      OpCodes.close -> apply_mask(mask, payload) |> parse_status_code
      OpCodes.ping -> rest
      _ -> apply_mask(mask, payload)
    end
   %{fin: fin, opcode: opcode, data: data}
  end

  def parse_unmasked_frame(<<fin::1, 0::3, opcode::4, 0::1, paylen::7>> <> rest, _opts \\ %{}) do
    rest = strip_paylen_bits(paylen, rest)
    data = case opcode do
      OpCodes.close -> parse_status_code(rest)
      _ -> rest
    end

    %{fin: fin, opcode: opcode, data: data}
  end

  def make_unmasked_frame(msg, opcode) do  # only supports single-frame messages atm
    {paylen, paylen_bits} = get_msg_paylen_and_bits(msg)
    <<1::1, 0::3, opcode::4, 0::1, paylen::7>> <> paylen_bits <> msg
  end

  def make_masked_frame(msg, opcode, mask) do  # only supports single-frame messages atm
    {paylen, paylen_bits} = get_msg_paylen_and_bits(msg)
    payload = apply_mask(mask, msg)
    <<1::1, 0::3, opcode::4, 1::1, paylen::7>> <> paylen_bits <> mask <> payload
  end

  defp parse_status_code(payload) do
    <<status_code::unsigned-big-integer-size(16)>> <> message = payload
    {status_code, message}
  end

  defp strip_paylen_bits(paylen, rest) do
    num_paylen_bytes = Map.get(%{127 => 8, 126 => 2}, paylen, 0)
    :binary.part(rest, {num_paylen_bytes, byte_size(rest)})
  end

  defp get_msg_paylen_and_bits(msg) do
    msg_length = String.length(msg)
    cond do
      msg_length > @max_uint_16 -> {127, <<msg_length::64>>}
      msg_length > 125 -> {126, <<msg_length::unsigned-big-integer-size(16)>>}
      msg_length < 124 -> {msg_length, ""}
    end
  end

  defp apply_mask(mask, payload) do
    mask_cycle = mask |> :binary.bin_to_list |> Stream.cycle
    xor = fn {b1, b2} -> Bitwise.^^^(b1, b2) end
    payload |> :binary.bin_to_list |> Enum.zip(mask_cycle) |> Enum.map(xor) |> to_string
  end
end
