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

    def build_container(tag , &block)
      unless tag.type == :container
        fail "Tag #{method} is not a container type"
      end
      @dmap_stack << TagContainer.new(tag)
      instance_eval(&block)
      if @dmap_stack.length > 1
        @dmap_stack.last.value << @dmap_stack.pop
      else
        return @result = @dmap_stack.pop
      end
    end

    def method_missing(method, *args, &block)
      tag = TagDefinition[method]
      return super if tag.nil?

      if block_given?
        build_container(tag, &block)
      else
        if @dmap_stack.length > 0
          args = args.size > 1 ? args : args.first
          @dmap_stack.last.value << Tag.new(tag, args)
        else
          fail 'Cannot build DMAP without a valid container'
        end
      end
    end
  end
end
