require_relative "../lib/sourcerer.rb"

test= Proc.new do |*params|

  puts "some awsome code here"

end

def hello_this sym
    puts "this is the Body!"
end

# todo -> more advanced regex for params
# ,options={},*args, &block


method_source= method(:hello_this).source
#Proc.new{ |sup,yo,lazy=nil,*params|
#
#  puts "this is the Body!"
#
#}

proc_source= test.source
#Proc.new{ |*params|
#
#  puts "some awsome code here"
#
#}

# example for terminal run
puts method_source,"---"
puts method_source.body,"---"
puts method_source.params,"---"
puts method_source.parameters.inspect,"---"

puts "\n"

merged_proc= ( method_source.body +
    proc_source.body
).build(*(method_source.params+proc_source.params))
puts merged_proc
puts merged_proc.to_proc
puts merged_proc.to_proc.source


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

class A

  class << self

    def hello test=nil
      puts "world!"
    end

  end

  def self.singleton test=nil
    puts "singleton"
  end

  def instance          hello= "wolrd"
    puts "instance"
  end

end

puts A.instance_method(:instance).source

puts A.method(:singleton).source


#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>