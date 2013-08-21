module DACPClient
  # This class provides a DSL to create DMAP responses
  class DMAPBuilder
    attr_reader :result

    def initialize
      @dmap_stack = []
    end

    def self.method_missing(method, *args, &block)
      new.send(method, *args, &block)
    end

    def method_missing(method, *args, &block)
      if method.to_s.length != 4 ||
        (tag = TagDefinitions.find { |a| a.tag.to_s == method.to_s }).nil?
        return super
      end
      if block_given?
        if tag.type == :container
          @dmap_stack << TagContainer.new(tag)
          instance_eval(&block)
          if @dmap_stack.length > 1
            @dmap_stack.last.value << @dmap_stack.pop
          else
            return @result = @dmap_stack.pop
          end
        else
          raise "Tag #{method} is not a container type"
        end
      else
        if @dmap_stack.length > 0
          args = args.size > 1 ? args : args.first
          @dmap_stack.last.value << Tag.new(tag, args)
        else
          raise 'Cannot build DMAP without a valid container'
        end
      end
    end
  end
end