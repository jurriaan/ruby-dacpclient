module DACPClient
  # The TagContainer class is a Tag which contains other Tags
  class TagContainer < Tag
    def initialize(type = nil, value = [])
      super type, value
    end

    def inspect(level = 0)
      "#{'  ' * level}#{type}:\n" + value.reduce('') do |a, e|
        a + e.inspect(level + 1).chomp + "\n"
      end
    end

    def get_value(key)
      return value[key] if key.is_a? Fixnum

      key = key.to_s
      val = value.find { |e| e.type.tag == key }
      val = value.find { |e| e.type.name == key } if val.nil?

      if val.type.type == :container
        val
      elsif !val.nil?
        val.value
      end
    end

    alias_method :[], :get_value

    def has?(key)
      key = key.to_s
      val = value.find { |e| e.type.tag == key }
      val = value.find { |e| e.type.name == key } if val.nil?
      !val.nil?
    end

    def method_missing(method, *arguments, &block)
      get_value(method.to_s)
    end

    def to_a
      value
    end
  end
end