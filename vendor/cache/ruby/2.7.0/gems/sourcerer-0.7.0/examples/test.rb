require_relative "../lib/sourcerer.rb"

simple_process_definition= Proc.new{ |variable|

  if variable.class == String
    puts "OMG it's a string"
  else
    puts "meh..."
  end

}


simple_process_definition.source

puts $TEST