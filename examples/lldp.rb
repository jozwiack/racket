#!/usr/bin/env ruby
#
# Send LLDP packet containing only mandatory TLVs:
# 1. Chassis ID TLV
# 2. Port ID TLV
# 3. TTL TLV
# + End of LLDP TLV
require 'rubygems'
require 'racket'

include Racket

unless (ARGV.size == 1)
  puts "Usage: #{$0} <iface>"
  exit
end

n = Racket::Racket.new
n.iface = ARGV[0]

n.l2 = L2::Ethernet.new
# LLDP ethertype = 0x88cc
n.l2.ethertype = 0x88cc
n.l2.dst_mac = "01:80:c2:00:00:0e"

n.l3 = L3::LLDP.new

# Chassis ID
#
# ID Subtype = 4 (MAC address)
chassis_sub = "\x04"
# ID = ff:ff:ff:ff:ff:ff
chassis_id = "\xff\xff\xff\xff\xff\xff"
n.l3.add_tlv(1,(chassis_sub+chassis_id).size,chassis_sub+chassis_id)

# Port ID
#
# ID Subtype = 7 (Locally assigned)
port_sub = "\x07"
# ID = "1"
port_id = "\x31"
n.l3.add_tlv(2,(port_sub+port_id).size,port_sub+port_id)

# TTL
#
# TTL = 360s
ttl = "\x01\x68"
n.l3.add_tlv(3,ttl.size,ttl)

# End of LLDPDU
n.l3.add_tlv(0,0)

b = n.sendpacket
puts "Sent #{b} bytes"
