module DACPClient
  class Model
    class DMAPAttribute < Struct.new(:tag, :item_class, :value)
      def initialize(tag, item_class = nil)
        super tag, item_class, nil
      end
    end

    def initialize(params = {})
      if params.is_a? DMAPParser::TagContainer
        deserialize(params)
      elsif params
        params.each do |attr, value|
          public_send("#{attr}=", value)
        end
      end
    end

    def inspect
      puts self.class.name
      dmap_attributes.each do |key, value|
        puts "  #{key}: #{value.value}"
      end
    end

    def to_s
      "#<#{self.class.name} " +  dmap_attributes.map do |key, value|
        "#{key}: #{value.value}"
      end.join(', ') + '>'
    end

    def to_dmap
      attributes = dmap_attributes
      DMAPParser::Builder.send dmap_tag do
        attributes.values.each do |value|
          send(value.tag, value.value)
        end
      end.to_dmap
    end

    def respond_to?(method)
      dmap_attributes.key?(method)
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /(.*)\=$/ &&
         dmap_attributes.key?(Regexp.last_match[1].to_sym)
        dmap_attributes[Regexp.last_match[1].to_sym].value = args.first
      elsif method.to_s =~ /(.*)\?$/ &&
            dmap_attributes.key?(Regexp.last_match[1].to_sym)
        dmap_attributes[Regexp.last_match[1].to_sym].value
      elsif dmap_attributes.key? method
        dmap_attributes[method].value
      else
        super
      end
    end

    class << self
      def dmap_attribute(method, key)
        @dmap_attributes ||= {}
        @dmap_attributes[method] = key
      end

      def dmap_container(method, key, item_class)
        @dmap_attributes ||= {}
        @dmap_attributes[method] = [key, item_class]
      end

      def dmap_tag(tag = nil)
        if tag
          @dmap_tag = tag
        else
          @dmap_tag
        end
      end

      def build_dmap(params = {})
        new(params).to_dmap
      end
    end

    private

    def deserialize(data)
      warn 'Invalid tag' if data.type.tag.to_sym != dmap_tag
      dmap_attributes.values.each do |value|
        value.value = get_value(data, value) if data.respond_to? value.tag
      end
      self
    end

    def get_value(data, value)
      item_class = value.item_class
      if item_class
        data.send(value.tag).to_a.map do |item|
          item_class.new(item) if item_class.dmap_tag == item.type.tag.to_sym
        end.compact
      else
        data.send(value.tag)
      end
    end

    def dmap_attributes
      @dmap_attributes ||= initialize_attributes
    end

    def initialize_attributes
      class_attributes = self.class.instance_variable_get(:@dmap_attributes)
      attributes = {}
      class_attributes.map do |key, value|
        attributes[key] = DMAPAttribute.new(*value)
      end
      attributes
    end

    def dmap_tag
      self.class.instance_variable_get(:@dmap_tag)
    end
  end
end
