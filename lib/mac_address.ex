defmodule MACAddress do
  @moduledoc """
  This module provides common functions for working with MAC addresses.

  ## Overview

  `MACAddress` offers helper functions and generally makes working with MAC addresses easier in Elixir.

  A major focus of this module is to support consumers of MAC addresses such as cryptographically secure ID generators, commonly found in distributed systems.

  ## Limitations

  Working with MAC addresses in Elixir is typically done through the `:inet` module. As such, any limitations that exist in `:inet` are typically true here as well. Most notably, this includes situations where querying addresses requires super user privileges, such as has been observed on Solaris.

  """

  import Bitwise

  @typedoc """
  String name of an interface.
  """
  @type interface_name :: String.t()

  @typedoc """
  MAC address Elixir binary.
  """
  @type mac_address :: <<_::48>>

  defguard is_mac_address(mac_address) when is_binary(mac_address) and byte_size(mac_address) == 6

  @doc """
  Returns a tuple of interface name + mac address.

  Returns an error if there is a problem accessing the MAC addresses.

  The returned MAC addresses are limited to those readable by the `:inet` module.
  """
  @spec mac_addresses() :: {:ok, {interface_name(), [mac_address()]}} | {:error, :inet.posix()}
  def mac_addresses() do
    with {:ok, if_addresses} <- :inet.getifaddrs() do
      {:ok, extract_mac_addresses(if_addresses)}
    end
  end

  defp extract_mac_addresses(if_addresses) do
    Enum.reduce(if_addresses, [],
      fn ({if_id, if_data}, acc) ->
        case Keyword.get(if_data, :hwaddr) |> maybe_address() do
          {:ok, mac_address} -> [{to_string(if_id), mac_address} | acc]
          _ -> acc
        end
      end
    )
  end

  defp maybe_address(address) do
    case address do
      nil -> :error
      0 -> :error
      [0, 0, 0, 0, 0, 0] -> :error
      [_, _, _, _, _, _] = addr -> {:ok, addr |> IO.iodata_to_binary()}
      _ -> :error
    end
  end

  defp extract_address_from(if_addresses, interface_name) do
    interface_id = to_charlist(interface_name)
    Enum.reduce_while(if_addresses, nil,
      fn ({if_id, if_data}, acc) ->
        with true <- if_id == interface_id,
             {:ok, _mac_address} = found_address <- Keyword.get(if_data, :hwaddr) |> maybe_address() do
          {:halt, found_address}
        else
          _ -> {:cont, acc}
        end
      end)
  end

  @doc """
  Returns the MAC address, if any, for the given interface name.

  The returned MAC address is limited by the `:inet` module.

  Returns an error if the given interface cannot be found or doesn't have a valid MAC address.
  """
  @spec mac_address(interface_name()) :: {:ok, mac_address()} | {:error, :inet.posix()} | :error
  def mac_address(interface_name) do
    with {:ok, if_addresses} <- :inet.getifaddrs() do
      extract_address_from(if_addresses, interface_name)
    else
      {:error, _reason} = err -> err
      _ -> :error
    end
  end

  @doc """
  Returns the MAC address, if any, for the given interface name.

  The returned MAC address is limited by the `:inet` module.
  """
  @spec mac_address!(interface_name()) :: mac_address()
  def mac_address!(interface_name) do
    case mac_address(interface_name) do
      {:ok, mac_address} -> mac_address
      _ -> raise ArgumentError, "unable to obtain a MAC address for the given interface name."
    end
  end

  @doc """
  Munges a MAC address in a cryptographically secure way so it no longer leaks public details but maintains uniqueness.

  Selects the first MAC address found, and if none are available, it will generate a random MAC address using `broadcast_address/1`.

  See `munge_address/2` for passing a specific MAC address.

  Useful for anything that may publicly expose a MAC address to the outside world, such as an ID generator. Ex: Twitter Snowflake.
  """
  @spec munge_address() :: mac_address()
  def munge_address() do
    mac_address = case mac_addresses() do
      {:ok, found_mac_addresses} ->
        {_interface, mac_address} = found_mac_addresses |> Enum.at(0)
        mac_address
      _ -> broadcast_address()
    end

    do_munge_address(mac_address)
  end

  @doc """
  Given a MAC address, munges the MAC address in a cryptographically secure way so it no longer leaks public details but maintains uniqueness.

  Useful for anything that may publicly expose a MAC address to the outside world, such as an ID generator. Ex: Twitter Snowflake.
  """
  @spec munge_address(mac_address()) :: mac_address()
  def munge_address(mac_address) when is_list(mac_address) and length(mac_address) == 6 do
    do_munge_address(mac_address)
  end

  def munge_address(mac_address) when is_mac_address(mac_address) do
    do_munge_address(mac_address)
  end

  defp do_munge_address(mac_address) do
    :crypto.strong_rand_bytes(6) |> :crypto.exor(mac_address)
  end

  @doc """
  Creates a cryptographically secure random MAC address with the broadcast bit set.

  Useful for ID generation, testing, etc.
  """
  @spec broadcast_address() :: mac_address()
  def broadcast_address() do
    :crypto.strong_rand_bytes(6) |> do_broadcast_address()
  end

  defp do_broadcast_address(<<b1::unsigned-integer-unit(8)-size(1), rest::binary-size(5)>>) do
    <<(b1 ^^^ 0x1)::unsigned-integer-unit(8)-size(1), rest::binary-size(5)>>
  end

  @doc """
  Converts a MAC address from a string hex representation to an Elixir binary representation.

  If the address cannot be converted, `:error` is returned.

  ## Options

  The accepted options are:

    * `:separators` - A list of binaries that are possible separators. Defaults to ":" and "-" if none are specified.

  ## Examples

      iex> MACAddress.from_hex("00:A0:C9:14:C8:29")
      {:ok, <<0, 160, 201, 20, 200, 41>>}

      iex> MACAddress.from_hex("00-A0-C9-14-C8-29")
      {:ok, <<0, 160, 201, 20, 200, 41>>}

      iex> MACAddress.from_hex("00*A0*C9*14*C8*29", separators: "*")
      {:ok, <<0, 160, 201, 20, 200, 41>>}

      iex> MACAddress.from_hex("F")
      :error

  """
  @spec from_hex(binary(), keyword()) :: {:ok, mac_address()} | :error
  def from_hex(hex_string, opts \\ []) when is_binary(hex_string) do
    separators = Keyword.get(opts, :separators, [":", "-"])
    do_from_hex(hex_string, separators)
  end

  @doc """
  Converts a MAC address from a string hex representation to an Elixir binary representation.

  If the address cannot be converted, an exception is raised.

  ## Options

  The accepted options are:

    * `:separators` - A list of binaries that are possible separators. Defaults to ":" and "-" if none are specified.

  ## Examples

      iex> MACAddress.from_hex!("00:A0:C9:14:C8:29")
      <<0, 160, 201, 20, 200, 41>>

      iex>  MACAddress.from_hex!("06-b0-b9-42-d8-42", separators: ["-"])
      <<6, 176, 185, 66, 216, 66>>


      iex> MACAddress.from_hex!("06b0b942d842")
      <<6, 176, 185, 66, 216, 66>>

      iex> MACAddress.from_hex!("06%%b0%%b9%%42%%d8%%42", separators: "%%")
      <<6, 176, 185, 66, 216, 66>>

  """
  @spec from_hex!(charlist() | binary(), keyword()) :: mac_address()
  def from_hex!(hex_data, opts \\ []) do
    case from_hex(hex_data, opts) do
      {:ok, mac_address} -> mac_address
      _ -> raise ArgumentError, "invalid mac address"
    end
  end

  defp do_from_hex(hex_string, separators) do
    case :binary.replace(hex_string, separators, "", [:global])
         |> String.downcase()
         |> Base.decode16(case: :lower) do
      {:ok, bin} = res when byte_size(bin) == 6 -> res
      _ -> :error
    end
  end

  @doc """
  Converts a MAC binary to a hex formatted string with optional separators.

  ## Options

  The accepted options are:

    * `:case` - specifies the character case to use when encoding
    * `:separator` - specifies the separator between each hex byte.

  The values for `:case` can be:

    * `:upper` - uses upper case characters

    * `:lower` - uses lower case characters (default)

  `:separator` may be any valid binary. Defaults to `:`.

  ## Examples

      iex> MACAddress.to_hex(<<6, 176, 185, 66, 216, 66>>)
      "06:b0:b9:42:d8:42"

      iex>  MACAddress.to_hex(<<6, 176, 185, 66, 216, 66>>, case: :upper)
      "06:B0:B9:42:D8:42"

      iex>  MACAddress.to_hex(<<6, 176, 185, 66, 216, 66>>, case: :lower, separator: "-")
      "06-b0-b9-42-d8-42"

      iex> MACAddress.to_hex(<<6, 176, 185, 66, 216, 66>>, case: :lower, separator: "")
      "06b0b942d842"

  """
  @spec to_hex(mac_address(), keyword()) :: binary()
  def to_hex(mac_address, opts \\ []) when is_mac_address(mac_address) do
    base_case = Keyword.get(opts, :case, :lower)
    separator = Keyword.get(opts, :separator, ":")
    do_to_hex(mac_address |> Base.encode16(case: base_case) |> to_charlist(), [], separator |> to_charlist())
  end

  defp do_to_hex([c1, c2], acc, _separator) do
    [c2 | [c1 | acc]] |> Enum.reverse() |> to_string()
  end

  defp do_to_hex([c1, c2 | rest], acc, separator) do
    do_to_hex(rest, [separator | [c2 |[c1 | acc]]], separator)
  end

  # This will not work on windows, but leaving it here if there is a desire to implement an OS command approach per-OS.
  # I prefer to wrap C, however for deeper functionality than risk OS commands, at least not without caveats.
  #  def nix_mac_address(interface_name) do
  #    :os.cmd(['ifconfig ', to_charlist(interface_name), '| grep -Eo \'([[:xdigit:]]{1,2}[:-]){5}[[:xdigit:]]{1,2}\' | head -n1'])
  #  end
  # :: 2> /dev/null; ifconfig en0 | grep -Eo '([[:xdigit:]]{1,2}[:-]){5}[[:xdigit:]]{1,2}' | head -n1;<<::
  # for /f %%i in ('wmic nic get  MACAddress ^|find ":"') do @echo %%i;
  # ::

end
