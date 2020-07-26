sourcerer
=========

Source code reader to make eval able proc source codes from methods , unbound methods, and processes (+ lambda)

it will always return a proc code like "Proc.new { super_code_here }"
check examples how easy to get source code.

### Install

bash:

    $ gem install sourcerer

Gemfile:

```ruby

    gem 'sourcerer'

```

### Example

```ruby

    require "sourcerer"

    #> input
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

    puts asdf.source
    puts asd.source
    puts method(:test).source

    #> output

    # Proc.new {
    #
    #   puts "hy"
    #
    # }
    #
    # Proc.new { |var, opts={}, *args, &block|
    #
    #   puts "WHAAAAAAAAAT?"
    #
    #   puts opts.inspect
    #
    # }
    #
    # Proc.new { |var, opts={}, *args, &block|
    #   puts var
    #   if true
    #
    #   end
    # }
    #

```

### SourceCode

you can invoke the :body & :params methods on the source code to trim out the code string parts

```ruby

    proc_obj.source.body
    proc_obj.source.params


```

### after words

if you find any bug please report to me :)