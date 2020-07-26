# coding: utf-8

require File.expand_path(File.join(File.dirname(__FILE__),"files.rb"))

### Specification for the new Gem
Gem::Specification.new do |spec|

  spec.name          = "sourcerer"
  spec.version       = File.open(File.join(File.dirname(__FILE__),"VERSION")).read.split("\n")[0].chomp.gsub(' ','')
  spec.authors       = ["Adam Luzsi"]
  spec.email         = ["adamluzsi@gmail.com"]
  spec.description   = %q{ DSL for for simple to use proc source generating from methods, unbound methods and of course Proc/lambda. It will allow you to play with the source or even fuse two source code to make a new one and generate a proc from that. }
  spec.summary       = %q{Simple source extractor Based on standard CRuby}
  spec.homepage      = "https://github.com/adamluzsi/sourcerer"
  spec.license       = "MIT"

  spec.files         = Sourcerer::SpecFiles
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  ##=======Runtime-ENV================##
  #spec.add_runtime_dependency "asdf", ['~>4.1.3']

  ##=======Development-ENV============##
  #spec.add_development_dependency "asdf",['~>4.1.3']

end
