module Cabbage

  module EmailParser

    require_relative "../string_extras"
    
    def EmailParser.parse_email(source)
      return {} if source.empty?
      results = { :header => {}, :original_keys => {}, :body => [] }
      divided = source.strip.match(/\A\s*(.+?)(?:\r\n\r\n|\n\n)(.+)/m)
      raw_header = divided[1]
      raw_body = divided[2]
      raw_header.gsub(/\n\s+/, " ").split("\n").each do |this_line|
        this_pair = this_line.split(/:\s*/, 2)
        this_key_string = this_pair[0].strip
        this_key_symbol = this_key_string.down_under.intern
        this_value = this_pair[1]
        if results[:header].has_key?(this_key_symbol)
          unless results[:header][this_key_symbol].class == Array
            results[:header][this_key_symbol] = [results[:header][this_key_symbol]]
          end
          results[:header][this_key_symbol] << this_value
        else
          results[:header][this_key_symbol] = this_value.strip
          results[:original_keys][this_key_symbol] = this_key_string
        end
      end
      if results[:header][:content_type].start_with?("multipart")
        boundary = EmailParser.extract_value(results[:header][:content_type], "boundary")
        EmailParser.break_by_boundary(raw_body, boundary).each {|n| results[:body] << EmailParser.parse_email(n)}
      else
        results[:body] = raw_body
      end
      results
    end

    def EmailParser.break_by_boundary(source, boundary)
      source.split("--" + boundary).keep_if {|n| n != "--" && n != ""}.each {|n| n.strip!}
    end

    def EmailParser.extract_value(target_string, key)
      target_string.match(/#{key}=["']?([^;\s"']+)/i)[1]
    end

  end # end Parser module

end