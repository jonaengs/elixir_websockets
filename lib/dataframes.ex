defmodule DataFrames do
  require OpCodes

  @max_uint_16 65536

  '''
  Parses a received dataframe.
  Returns map of the following values:
  * fin in (0, 1). 1 if final frame in message, 0 otherwise.
  * opcode in (0, 15).
  * 1 is mask bit. Client frames must be masked
  * payload is bitstring. When opcode is 8 it is a pair {status_code: int, message: bitstring}
  '''
  def parse_client_dataframe( # meaning sent from client. Client frames must be masked
    <<fin::1, _rsv::3, opcode::4, 1::1, paylen::7>> <> rest
  )
  do
    mask_and_payload = strip_paylen_bits(paylen, rest)
    <<mask::32, payload::bitstring>> = mask_and_payload
    mask = <<mask::32>>
    data = case opcode do
      OpCodes.close -> apply_mask(mask, payload) |> parse_status_code  # Close
      OpCodes.ping -> rest # Ping. Return exact same data
      _ -> apply_mask(mask, payload)
    end

   %{fin: fin, opcode: opcode, data: data}
  end

  def parse_server_dataframe(
    <<fin::1, _rsv::3, opcode::4, 0::1, paylen::7>> <> rest
  ) do
    rest = strip_paylen_bits(paylen, rest)
    data =
    case opcode do
      OpCodes.close -> parse_status_code(rest)  # Close
      _ -> rest
    end

    %{fin: fin, opcode: opcode, data: data}
  end

  def parse_status_code(payload) do
    <<status_code::unsigned-big-integer-size(16), message::bitstring>> = payload
    {status_code, message}
  end

  def strip_paylen_bits(paylen, rest) do
    cond do
      paylen == 127 ->
        <<_paylen::64>> <> rest = rest
        rest
      paylen == 126 ->
        <<_paylen::16>> <> rest = rest
        rest
      true -> rest
    end
  end

  def get_msg_paylen_and_bits(msg) do
    msg_length = String.length(msg)
    cond do
      msg_length > @max_uint_16 -> {127, <<msg_length::64>>}
      msg_length > 125 -> {126, <<msg_length::unsigned-big-integer-size(16)>>}
      msg_length < 124 -> {msg_length, ""}
    end
  end

  def make_server_dataframe(msg, opcode) do  # only supports single-frame messages atm
    {paylen, paylen_bits} = get_msg_paylen_and_bits(msg)
    <<1::1, 0::3, opcode::4, paylen::8>> <> paylen_bits <> msg
  end

  def make_client_dataframe(msg, opcode, mask) do  # only supports single-frame messages atm
    {paylen, paylen_bits} = get_msg_paylen_and_bits(msg)
    payload = apply_mask(mask, msg)
    <<1::1, 0::3, opcode::4, 1::1, paylen::7>> <> paylen_bits <> mask <> payload
  end

  def apply_mask(mask, payload) do
    mask_cycle = mask |> :binary.bin_to_list |> Stream.cycle
    xor = fn {b1, b2} -> Bitwise.^^^(b1, b2) end
    payload |> :binary.bin_to_list |> Enum.zip(mask_cycle) |> Enum.map(xor) |> to_string
  end
end
