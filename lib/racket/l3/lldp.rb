module Racket
module L3
# Link Layer Discovery Protocol (LLDP)
#
# http://standards.ieee.org/getieee802/download/802.1AB-2009.pdf
class LLDP < RacketPart
  # Protocol is just a set of TLVs - there are no fixed fields
  rest :payload

  # Not so elegant solution for handling fields which are not byte aligned
  # T = 0..127, L = 0..511 (until you're not fuzzing)
  def add_tlv(t,l,v=nil)
    tlv = [(t << 9) + l, v]
    self.payload += tlv.flatten.pack("na*")
  end
end
end
end
