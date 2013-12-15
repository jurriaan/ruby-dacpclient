require 'dacpclient/tag_definitions'
require 'dacpclient/dmapconverter'

require 'stringio'
module DACPClient
  # The DMAPParser class parses DMAP responses
  class DMAPParser
    def self.parse(response)
      return nil if response.nil? || response.length < 8
      response = StringIO.new(response)
      ret = TagContainer.new
      key = response.read(4)
      ret.type = TagDefinition[key]
      response.read(4) # ignore length for now
      ret.value = parse_container(response)
      ret
    end

    private

    def self.parse_container(response)
      values = []

      until response.eof?
        key = response.read(4)
        length = DMAPConverter.bin_to_int(response.read(4))
        data = response.read(length)
        tag = TagDefinition[key] ||
              TagDefinition.new(key, :unknown, "unknown (#{data.bytesize})")
        if tag.type == :container
          data = StringIO.new(data)
          values << TagContainer.new(tag, parse_container(data))
        else
          values << Tag.new(tag, DMAPConverter.decode(tag.type, data))
        end
      end
      values
    end
  end
end
