
require "sourcerer"

def test var, opts={}, *args, &block
  puts var
  if true

  end
end

asdf= lambda{

  puts "hy"

}

asd = Proc.new { |var, opts={}, *args, &block|

  puts "WHAAAAAAAAAT?"

  puts opts.inspect

}

class HelloWorld

  #> TODO: comment remove from args
  def self.hello sym,sym2= "#{sym}", options={},*params,&block

    [1,2,3].each do |do_|

      puts do_    # comment

    end

    puts "some code" # some comment

  end

end

#> output
test2= Proc.new do |sym,options={},*params,&block|

  puts "some awsome code here"  # comment
  puts "yo"

end # Proc

puts asdf.source.body
puts asd.source.body
puts asd.source.params
# puts method(:test).source
# puts test2.source
# puts HelloWorld.method(:hello).source

