require_relative "parser"
require_relative "mime_part"
module Cabbage
  class Email
    include EmailParser

    def initialize(source = "")
      @raw_source = ""
      @raw_parsed = {}
      @header = {}
      @original_keys = {}
      @parts = []
      @multipart = false
      if source != nil && source.class.to_s == "String"
        if source.include?("\n")
          @raw_source = source
          parse()
        else
          load_and_parse(source)
        end
      else
        raise "Bad input to Cabbage::Email#new."
      end
    end

    attr_reader :raw_source, :raw_parsed, :header, :original_keys, :parts, :multipart

    def method_missing(m, *args, &block)
      if @header.keys.include?(m.intern)
        @header[m.intern]
      else
        raise "undefined method in Cabbage::Email"
      end
    end

    def load(filename)
      open(filename) {|f| @raw_source = f.read }
    end

    def load_and_parse(filename)
      open(filename) {|f| @raw_source = f.read }
      parse()
    end

    def parse
      if @raw_source.empty?
        puts "Nothing to parse."
        return false
      else
        @raw_parsed = EmailParser.parse_email(@raw_source)
      end
      @header = @raw_parsed[:header]
      @original_keys = @raw_parsed[:original_keys]
      if header[:content_type].include?("multipart")
        @multipart = true
        make_flat(@raw_parsed).each do |raw_part|
          @parts << MimePart.new(raw_part)
        end
      else
        make_flat(@raw_parsed).each do |raw_part|
          @parts << MimePart.new(raw_part)
        end    
      end
      return true
    end

    def multipart?
      @multipart
    end

    def [](key)
      if @header.has_key?(key)
        @header[key]
      elsif key == :body
        self.body
      elsif self.mime_types.include?(key)
        @parts[self.mime_types.index(key)].body
      elsif key.class == FixNum

      else
        nil
      end
    end

    def keys
      @header.keys + [:body] + self.mime_types 
    end

    def attachments
      [].tap do |output|
        @parts.each do |part|
          output << part if part.attachment?
        end
      end
    end

    # returns an array of strings representing available
    # mime types in the array of mime parts.
    def mime_types
      [].tap do |result|
        @parts.each do |part|
          result << part.content_type
        end
      end
    end

    def body(type = "text/plain")
      if @multipart
        if self.mime_types.include?(type)
          @parts[self.mime_types.index(type)].body
        elsif @parts.size > 0
          @parts[0].body
        else
          nil
        end
      else
        @raw_parsed[:body]
      end
    end

    #####################################################################
    ########################## PRIVATE METHODS ##########################
    #####################################################################

    private

    def make_flat(tree)
      results = []

      if tree[:body].class == Hash
        tree[:body].each do |this_part|
          if this_part[:header][:content_type] =~ /^multipart/
            results << make_flat(this_part)
          else
            results << this_part
          end
        end
      elsif tree[:body].class == String
        results << tree
      else
        # something went wrong
      end
      return results.flatten
    end

  end # end Message class

end # end Jmail module
