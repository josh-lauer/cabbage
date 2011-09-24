#!/usr/bin/env ruby
# encoding: UTF-8
module Cabbage

  # just pass calls to new on to DotFile class for now
  def self.new(*args, &block)
    DotFile.new(args[0], &block) # passes the the first argument on
  end

  def self.dotfile(*args, &block)
    DotFile.new(args[0], &block) # passes the the first argument on
  end

  class DotFile
   
    # pass it a string containing either the DotFile itself, or the path to
    # a DOTfile.
    def initialize(source = nil)
      @raw_dotfile = ""  # unparsed DOTfile
      @type = ""         # 
      @title = ""
      @header = {}
      @tables = {}
      @connections = []
      source != nil if parse(source)
    end

    attr_accessor :raw_dotfile, :type, :title, :header, :tables, :connections

    def parse(source = nil)
      begin
        if source.class == String
          if source.include?("\n")
            load_from_string(source)
          else
            load_from_file(source)
          end
          parse_dotfile()
        elsif source
          raise
        end
      rescue
        puts 'Unhandled parser exception, dropping to debugger'
        debugger
      end
    end 

    def load_from_file(dotfile_path)
      @raw_dotfile = IO.read(dotfile_path)
    end

    def load_from_string(dotfile)
      @raw_dotfile = dotfile
    end

    def parse_header(raw_header, delimiter)
      temp = {}
      raw_header.scan(/(\w+)(?:\s*=?\s*)(?:["|\[](.+?)["|\]]#{delimiter})/m).each do |n|
        if n[1].include?("=")
          temp[n[0]] = parse_header(n[1], ",")
        else
          temp[n[0]] = n[1]
        end
      end
      return temp
    end

    def parse_tables(raw_tables)
      {}.tap do |output|
        raw_tables.scan(/\s*\"*([\w:]+)\"*\s*\[\w+\s*=\s*<(.+?)>\];/m).each do |n|
          output[ n[0].gsub('\"', '').strip ] = n[1].strip
        end
      end
    end

    def parse_connections(node_chunk)
      output = []
      node_chunk.split("\n").each do |this_line|
        this_connection = {}
        temp = this_line.split("->")
        this_connection["node_from"] = temp[0].gsub('"', '').gsub('\\', '').strip
        this_connection["node_to"] = temp[1].split("[")[0].gsub('"', '').gsub('\\', '').strip
        tokens = temp[1].split("[")[1].split("]")[0].split(",")
        tokens.each do |token_string|
          token_pair = token_string.split("=")
          this_connection[token_pair[0].strip.gsub('"', '').gsub('\\', '')] = token_pair[1].strip.gsub('"', '').gsub('\\', '')
        end
        output << this_connection
      end
      return output
    end

    # structure:
    # title, header, tables, footer
    def parse_dotfile
      # the chunk is everything inside '{}'
      raw_chunk = @raw_dotfile.split("{")[1].split("}")[0].strip
      # pull out the header
      raw_header = raw_chunk.match(/([\w\s*=".,\s\[\]_\\]+;)*/m)[0]
      # find body by chopping header off chunk
      raw_body = raw_chunk.sub(raw_header, "")
      # split the body on '>];', which delimits the tables section
      raw_connections = raw_body.split(">];")[-1].strip
      # split out the tables section from the body
      raw_tables = raw_body.split(">];")[0 .. -2].join(">];").strip + " \n>];"

      # assemble the output hash
      @type = @raw_dotfile.match(/\A\s*((?:di)?graph)/)[1]
      @title = @raw_dotfile.match(/\A\s*(?:di)?graph\s*(\w+)/)[1]
      @header = parse_header(raw_header, ";")
      @tables = parse_tables(raw_tables)
      @connections = parse_connections(raw_connections)
    end

  end

end

