class DMAPConverter
  class << self
    def bin_to_byte data
      data.unpack('C').first
    end
    
    def bin_to_long data 
      (self.bin_to_int(data[0..3]) << 32) + self.bin_to_int(data[4..7])
    end
    
    def bin_to_int data
      data.unpack('N').first
    end
    
    def bin_to_short data
      data.unpack('n').first
    end
    
    def bin_to_bool data
      data == "\x01"
    end
    
    def bin_to_version data
      data.unpack('nCC').join '.'
    end
    
    def bin_to_hex data
      data.bytes.inject("") {|ret, b| ret += "%02X" % b}
    end
    
    def bool_to_bin data
      if data.true? 
        "\x01"
      else  
        "\x00"
      end
    end
    
    def int_to_bin data
      [data.to_i].pack 'N'
    end
    
    def byte_to_bin data
      [data.to_i].pack 'C' 
    end
    
    def long_to_bin data
      [data >> 32,  data & 0xfffffff].pack 'NN'
    end
    
    def short_to_bin data
      [data.to_i].pack 'n'
    end
    
    def version_to_bin data
      data.split('.').pack 'nCC'
    end
    
    def hex_to_bin data
      [data].pack 'H*'
    end
  end
end