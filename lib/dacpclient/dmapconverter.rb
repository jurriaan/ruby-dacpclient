module DACPClient
  # The DMAPConverter class converts between binary and ruby formats
  class DMAPConverter
    class << self
      def date_to_bin(data)
        int_to_bin(value.to_i)
      end

      def bin_to_byte(data)
        data.unpack('C').first
      end

      def bin_to_long(data)
        (bin_to_int(data[0..3]) << 32) + bin_to_int(data[4..7])
      end

      def bin_to_int(data)
        data.unpack('N').first
      end

      def bin_to_short(data)
        data.unpack('n').first
      end

      def bin_to_bool(data)
        data == "\x01"
      end

      def bin_to_version(data)
        data.unpack('nCC').join '.'
      end

      def bin_to_hex(data)
        data.bytes.reduce('') { |a, e| a + sprintf('%02X', e) }
      end

      def bin_to_date(data)
        Time.at(bin_to_int(data))
      end

      def bool_to_bin(data)
        (data ? 1 : 0).chr
      end

      def int_to_bin(data)
        [data.to_i].pack 'N'
      end

      def byte_to_bin(data)
        [data.to_i].pack 'C'
      end

      def long_to_bin(data)
        [data >> 32, data & 0xfffffff].pack 'NN'
      end

      def short_to_bin(data)
        [data.to_i].pack 'n'
      end

      def version_to_bin(data)
        data.split('.').pack 'nCC'
      end

      def hex_to_bin(data)
        [data].pack 'H*'
      end

      def decode_unknown(data)
        if data =~ /[^\x20-\x7e]/ # non-readable characters
          if data.bytesize == 1
            return DMAPConverter.bin_to_byte(data)
          elsif data.bytesize == 2
            return DMAPConverter.bin_to_short(data)
          elsif data.bytesize == 4
            return DMAPConverter.bin_to_int(data)
          elsif data.bytesize == 8
            return DMAPConverter.bin_to_long(data)
          end
        end
        data
      end

      def bin_to_string(data)
        data
      end
      alias_method :string_to_bin, :bin_to_string

      alias_method :uint16_to_bin, :short_to_bin
      alias_method :uint32_to_bin, :int_to_bin
      alias_method :uint64_to_bin, :long_to_bin

      alias_method :bin_to_uint16, :bin_to_short
      alias_method :bin_to_uint32, :bin_to_int
      alias_method :bin_to_uint64, :bin_to_long
      alias_method :bin_to_unknown, :decode_unknown

      def decode(type, data)
        decode_method = ('bin_to_' + type.to_s).to_sym
        if respond_to? decode_method
          send(decode_method, data)
        else
          warn "Decoder: Unknown type #{type}"
          decode_unknown(data)
        end
      end

      def encode(type, data)
        encode_method = (type.to_s + '_to_bin').to_sym
        if respond_to? encode_method
          send(encode_method, data)
        else
          warn "Encoder: Unknown type #{type}"
          data
        end
      end
    end
  end
end
