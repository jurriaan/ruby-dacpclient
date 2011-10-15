class DMAPBuilder
  attr_reader :result
  
  def initialize
    @dmap_stack = []
  end
  
  def method_missing method, *args, &block
    return super if method.to_s.length != 4 || (tag = DMAPParser::Types.find {|a| a.tag == method}).nil? 
    if block_given?
      if tag.type == :container
        @dmap_stack << DMAPParser::TagContainer.new(tag)
        instance_eval &block
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
        @dmap_stack.last.value << DMAPParser::Tag.new(tag, args.size > 1? args : args.first)
      else
        raise "Cannot build DMAP without a valid container"
      end
    end    
  end
end