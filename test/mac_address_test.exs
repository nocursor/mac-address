defmodule MACAddressTest do
  use ExUnit.Case, async: true
  doctest MACAddress

  @nil_address <<0, 0, 0, 0, 0, 0>>

  test "mac_addresses/0 returns a list of a mac addresses" do

    {:ok, mac_addresses} = MACAddress.mac_addresses()
    assert is_list(mac_addresses) == true
    if Enum.count(mac_addresses) > 0 do
      for {interface, mac_address} <- mac_addresses do
        assert String.valid?(interface) == true
        assert byte_size(mac_address) == 6
      end
    end
  end

  test "returns a mac address for the given interface" do
    # This test might fail if for some reason an interface changes during the test, but hey it's better than nothing
    # I have little interest in mocking it either
    {:ok, mac_addresses} = MACAddress.mac_addresses()
    assert is_list(mac_addresses) == true
    if Enum.count(mac_addresses) > 0 do
      {interface, mac_address} = Enum.at(mac_addresses, 0)
      {:ok, found_mac_addresses} = MACAddress.mac_address(interface)
      assert found_mac_addresses == mac_address
      assert MACAddress.mac_address!(interface) == found_mac_addresses
    end
  end

  test "munge_address/1 munges an existing MAC address" do
    address = <<243, 224, 22, 255, 240, 33>>
    munged_address = MACAddress.munge_address(address)
    assert is_binary(munged_address)
    assert byte_size(munged_address) == 6
    assert munged_address != @nil_address
    assert munged_address != address
  end


  test "munge_address/0 munges a MAC address" do
    munged_address = MACAddress.munge_address()
    assert is_binary(munged_address)
    assert byte_size(munged_address) == 6
    assert munged_address != @nil_address
  end

  test "broadcast_address/0 generates a broadcast MAC address" do
    broadcast_address = MACAddress.broadcast_address()
    assert is_binary(broadcast_address)
    assert byte_size(broadcast_address) == 6
    assert broadcast_address != @nil_address
    <<b1::8, _rest::binary-size(5)>> = broadcast_address
    assert b1 != 0
  end

  test "from_hex/2 parses hex formatted MAC addresses by default with dashes or colons" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.from_hex("75:df:40:2c:60:a2") == {:ok, mac_address}
    assert MACAddress.from_hex("75-df-40-2c-60-a2") == {:ok, mac_address}
  end

  test "from_hex/2 parses hex formatted MAC addresses with no separators" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.from_hex("75df402c60a2") == {:ok, mac_address}
  end

  test "from_hex/2 parses hex formatted MAC addresses with custom separators" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.from_hex("75$df$40$2c$60$a2", separators: ["$"]) == {:ok, mac_address}
    assert MACAddress.from_hex("75%df#40$2c$60%a2", separators: ["$", "%", "#"]) == {:ok, mac_address}
  end

  test "from_hex!/2 parses hex formatted MAC addresses by default with dashes or colons" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.from_hex!("75:df:40:2c:60:a2") == mac_address
    assert MACAddress.from_hex!("75-df-40-2c-60-a2") == mac_address
  end

  test "from_hex!/2 parses hex formatted MAC addresses with no separators" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.from_hex!("75df402c60a2") == mac_address
  end

  test "from_hex!/2 parses hex formatted MAC addresses with custom separators" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.from_hex!("75$df$40$2c$60$a2", separators: ["$"]) == mac_address
    assert MACAddress.from_hex!("75%df#40$2c$60%a2", separators: ["$", "%", "#"]) == mac_address
  end

  test "to_hex/2 converts a from a mac address binary to a hex formatted lower-case colon delimited string by default" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.to_hex(mac_address) == "75:df:40:2c:60:a2"
  end

  test "to_hex/2 converts a from a mac address using custom options for separator and case" do
    mac_address = <<0x75, 0xdf, 0x40, 0x2c, 0x60, 0xa2>>
    assert MACAddress.to_hex(mac_address, case: :lower) == "75:df:40:2c:60:a2"
    assert MACAddress.to_hex(mac_address, case: :upper) == "75:DF:40:2C:60:A2"
    assert MACAddress.to_hex(mac_address, case: :lower, separator: "-") == "75-df-40-2c-60-a2"
    assert MACAddress.to_hex(mac_address, case: :lower, separator: "BBQ") == "75BBQdfBBQ40BBQ2cBBQ60BBQa2"
  end

end


