module Cabbage
  class MimePart

    def initialize(raw_part)
      @raw_source = raw_part
      @header = raw_part[:header]
      @original_keys = raw_part[:original_keys]
      @body = raw_part[:body]
      @content_type = @header[:content_type].split(";")[0].strip
    end
    attr_accessor :raw_source, :header, :original_keys, :body, :content_type

    def method_missing(m, *args, &block)
      if @header.keys.include?(m.intern)
        @header[m.intern]
      else
        raise "undefined method in Cabbage::MimePart"
      end
    end

    def [](key)
      @header[key]
    end

    def keys
      @header.keys
    end

    def attachment?
      if @header.has_key?(:content_disposition) && @header[:content_disposition].start_with?("attachment")
        true
      else
        false
      end
    end

  end
end