require 'dacpclient/tag'
require 'dacpclient/tag_container'

module DACPClient
  # The TagDefinition class describes the tags
  TagDefinition = Struct.new(:tag, :type, :name) do
    def inspect
      "#{tag} (#{name}: #{type})"
    end

    def to_s
      "#{tag} (#{name}: #{type})"
    end

    class << self
      def find(key)
        @@tags[key.to_s]
      end

      def tag(*args, &block)
        @@tags ||= Hash.new(nil)
        definition = new(*args, &block).freeze
        @@tags[definition.tag.to_s] = definition
      end

      alias_method :[], :find
    end
  end
end