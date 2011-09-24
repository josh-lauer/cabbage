#!/usr/bin/env ruby
# encoding: UTF-8
require 'irb'
require 'ruby-debug'

class Object
  # Return only the methods not present on basic objects
  def interesting_methods
    (self.methods - Object.instance_methods).sort
  end
end

def reload
  load "parser.rb"
  @output = Cabbage.dotfile("ERD.dot")
end

@output = reload
# put stuff here you only want to run once
# ARGV.clear
IRB.setup nil
IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
require 'irb/ext/multi-irb'
IRB.irb nil, self
