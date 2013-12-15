module DACPClient
  Tag = Struct.new(:type, :value) do
    def to_s
      "#<#{self.class.name} #{type}>"
    end

    def inspect(level = 0)
      "#{'  ' * level}#{type}: #{value}"
    end

    def to_dmap
      value = self.value
      if type.type == :container
        value = value.reduce('') { |a, e| a + e.to_dmap }
      else
        value = DMAPConverter.encode(type.type, value)
      end
      type.tag.to_s + [value.length].pack('N') + value
    end
  end
end
