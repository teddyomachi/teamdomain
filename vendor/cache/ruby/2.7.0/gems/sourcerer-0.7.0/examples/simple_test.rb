require_relative "../lib/sourcerer.rb"

test= Proc.new do |sym,options={},*params,&block|

  puts "some awsome code here"  # comment
  puts "yo"

end # Proc

puts test.source

class HelloWorld

  def self.hello sym,sym2= "#{sym}", options={},*params,&block # the params

    [1,2,3].each do |do_|

      puts do_    # comment

    end

    puts "some code" # some comment

  end

end

puts HelloWorld.method(:hello).source
