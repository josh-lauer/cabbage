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
      @graph_type = ""   # 
      @title = ""
      @header = {}
      @nodes = []
      @connections = []
      source != nil if parse(source)
    end

    attr_accessor :raw_dotfile, :graph_type, :title, :header, :nodes, :connections

    # no public methods yet apart from accessors

    # parsing methods below
    private

    def load_from_file(dotfile_path)
      @raw_dotfile = IO.read(dotfile_path)
    end

    def load_from_string(dotfile)
      @raw_dotfile = dotfile
    end

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
        puts 'Unhandled parser exception! Parse failed.'
      end
    end 

    # a dotfile has four components:
    # graph_type, header, nodes, connections
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
      @graph_type = @raw_dotfile.match(/\A\s*((?:di)?graph)/)[1]
      @title = @raw_dotfile.match(/\A\s*(?:di)?graph\s*(\w+)/)[1]
      @header = parse_header(raw_header, ";")
      @nodes = parse_nodes(raw_tables)
      @connections = parse_connections(raw_connections)
    end

    def parse_header(raw_header, delimiter)
      temp = {}
      raw_header.scan(/(\w+)(?:\s*=?\s*)(?:["|\[](.+?)["|\]]#{delimiter})/m).each do |n|
        if n[1].include?("=")
          temp[n[0]] = parse_header(n[1], ",")
        else
          temp[n[0]] = n[1].strip
        end
      end
      return temp
    end

    def chop_tables(raw_tables)
      {}.tap do |output|
        raw_tables.scan(/\s*\"*([\w:]+)\"*\s*\[\w+\s*=\s*<(.+?)>\];/m).each do |n|
          output[ n[0].gsub('\"', '').strip ] = n[1].strip
        end
      end
    end

    def parse_nodes(raw_tables)
      result = []
      chop_tables(raw_tables).each do |name, table|
        node = {:name => name.sub("m_", "")}
        node[:fields] = []
        if table.include?("|")
          table.split("|")[1].scan(/port="([\w:]+)">[^<]+<[^>]+>(.+?)</m).each do |pair|
            node[:fields] << { :name => pair[0], :type => pair[1] }
          end
        end
        result << node
      end
      result
    end

    def parse_connections(node_chunk)
      output = []
      node_chunk.split("\n").each do |this_line|
        this_connection = {}
        temp = this_line.split("->")
        this_connection[:start_node] = temp[0].gsub('"', '').gsub('\\', '').sub('m_', '').strip
        this_connection[:end_node] = temp[1].split("[")[0].gsub('"', '').gsub('\\', '').sub('m_', '').strip
        tokens = temp[1].split("[")[1].split("]")[0].split(",")
        tokens.each do |token_string|
          token_pair = token_string.split("=")
          this_connection[token_pair[0].strip.gsub('"', '').gsub('\\', '').to_sym] = token_pair[1].strip.gsub('"', '').gsub('\\', '')
        end
        output << this_connection
      end
      return output
    end


  end

end

