module DACPClient
  module DMAPParser
    Tag = Struct.new(:type, :value) do
      def to_s
        "#<#{self.class.name} #{type}>"
      end
      
      def inspect(level = 0)
        "#{'  ' * level}#{type}: #{value}"
      end

      def to_dmap
        value = self.value
        value = case type.type
                when :container
                  value.reduce('') { |a, e| a += e.to_dmap }
                when :byte
                  DMAPConverter.byte_to_bin value
                when :uint16, :short
                  DMAPConverter.short_to_bin value
                when :uint32
                  DMAPConverter.int_to_bin value
                when :uint64
                  DMAPConverter.long_to_bin value
                when :bool
                  DMAPConverter.bool_to_bin value
                when :hex
                  DMAPConverter.hex_to_bin value
                when :string
                  value
                when :date
                  DMAPConverter.int_to_bin value.to_i
                when :version
                  DMAPConverter.version_to_bin value.to_i
                else
                  warn "Unknown type #{tag.type}"
                  # Tag.new tag, parseunknown(data)
                  value
                end
        type.tag.to_s + [value.length].pack('N') + value
      end
    end
  end
end