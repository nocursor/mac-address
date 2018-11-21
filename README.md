## MAC Address  
  
`MACAddress` provides common functions for working with [MAC addresses](https://en.wikipedia.org/wiki/MAC_address).

It is currently a work in progress, but you may find it immediately useful. The API, however, may be subject to change at this time.
  
`MACAddress` offers helper functions and generally makes working with MAC addresses easier in Elixir.
  
A major focus of this module is to support consumers of MAC addresses such as cryptographically secure ID generators, commonly found in distributed systems. It is currently being used to munge MAC addresses for use in custom ID generation to avoid leaking the real MAC address of each given machine to the public. It is also being used to parse and send data to/from pipes. This functionality was common across several libraries and applications, thus it is now its own library.

The general focus with regard to querying MAC addresses is to use the facilities provided by Erlang, and avoid custom scripts unless specifically called out. It is possible that OS command-versions may be available via other functions in the future to augment anything that might be lacking from Erlang and Elixir. For security reasons, this library tempts to avoid this approach that many other libraries take by default (often out of necessity).
 
## Usage

The API focuses on MAC addresses and providing Elixir-centric, pragmatic representations and to save boiler-plate. 

Get a list of all MAC addresses:

```elixir
MACAddress.mac_addresses()
{:ok,
 [
   {"bridge0", <<114, 0, 7, 196, 62, 91>>},
   {"en2", <<114, 0, 4, 171, 64, 91>>},
   {"en1", <<114, 0, 11, 176, 69, 96>>},
   {"awdl0", <<158, 82, 242, 191, 187, 141>>},
   {"p2p0", <<14, 64, 8, 144, 42, 70>>},
   {"en0", <<108, 64, 8, 144, 42, 71>>}
 ]}
```

Get the MAC address of a specific interface:

```elixir
 MACAddress.mac_address("en1")
{:ok, <<114, 0, 11, 176, 69, 96>>}

# or exception flavored
MACAddress.mac_address!("en2")
<<114, 0, 4, 171, 64, 91>>
```

Sometimes we want to munge our MAC address for public usage. After doing so, we typically would want to store it if we need it again. We might do this in a config, GenServer, Process, Agent, database, or ETS table as a new one will be generated each time.

Here's how we do it:

```elixir
MACAddress.munge_address(<<114, 0, 4, 171, 64, 91>>)  
<<248, 234, 234, 252, 80, 101>>

# we can also generate a munged address
# by default, it will grab the first mac address available, but if there are none, it generates one
MACAddress.munge_address()                             
<<27, 110, 236, 180, 44, 34>>

# we can also generate an address with the broadcast bits masked for us
MACAddress.broadcast_address()
<<225, 67, 238, 114, 151, 27>>
```

Convert a MAC address from a hex string, as often found in utilities such as ifconfig:

```elixir
# by default it will parse `:` or `-`
 MACAddress.from_hex("72:00:0b:b0:45:60")      
{:ok, <<114, 0, 11, 176, 69, 96>>}

# exception flavor
MACAddress.from_hex!("69:00:0c:b1:45:60")       
<<105, 0, 12, 177, 69, 96>>

# we can also control the separators to parse
MACAddress.from_hex!("69&00&0C&B1&45&60", separators: ["&"])
<<105, 0, 12, 177, 69, 96>>

# we can even have multiple separators if we have some weird format
MACAddress.from_hex!("69-00-0C&B1&45&60", separators: ["&", "-"])
<<105, 0, 12, 177, 69, 96>>
```

Format an Elixir binary MAC address in our familiar hex format:

```elixir
MACAddress.to_hex(<<114, 0, 11, 176, 69, 96>>)
"72:00:0b:b0:45:60"

# we can control the case
MACAddress.to_hex(<<114, 0, 11, 176, 69, 96>>, case: :upper)
"72:00:0B:B0:45:60"

# we can control the separator too
MACAddress.to_hex(<<114, 0, 11, 176, 69, 96>>, case: :upper, separator: "-")
"72-00-0B-B0-45-60"
```

Usage will expand with real-world requirements.

## Installation

`MACAddress` is available via [Hex](https://hex.pm/packages/mac_address). The package can be installed
by adding `mac_address` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mac_address, "~> 0.0.0.1"}
  ]
end
```

The API docs can be found at [https://hexdocs.pm/mac_address](https://hexdocs.pm/mac_address).

## Limitations

Working with MAC addresses in Elixir is typically done through the `:inet` module. As such, any limitations that exist in `:inet` are typically true here as well. Most notably, this includes situations where querying addresses requires super user privileges, such as has been observed on Solaris.

If you need more complex MAC address parsing or vendor identification, a number of packages exist for this purpose. The goal of this library is not to support every known MAC address format, such as those found in applications such as WireShark. Rather, this library is focused on the formats that appear within Elixir and Erlang internally and in major real-world usage.

## Issues/Features

If you have any feature requests, suggestions, or issues, please leave feedback in the issue tracker. I welcome contributions and changes.