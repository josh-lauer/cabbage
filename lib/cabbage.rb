module Cabbage

  # # You can't instantiate a cabbage. (yet)
  # def self.new(*args, &block)
  #
  # end

  # graphviz DOT format files
  def self.dotfile(*args, &block)
	  require_relative "cabbage/dotfile/parser" 
    DotFile.new(args[0], &block) # passes the the first argument on
  end

  # raw emails
  def self.email(*args, &block)
	  require_relative "cabbage/email/email"
    require_relative "cabbage/email/parser"
    require_relative "cabbage/string_extras"
    Email.new(args[0], &block)
  end

end