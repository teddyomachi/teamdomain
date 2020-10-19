#!/usr/bin/ruby -d

require 'rake'

spec = Gem::Specification.new do |s|
	s.author = 'Glenn Y. Rolland'
	s.email = 'glenux@glenux.net'
	s.homepage = 'http://code.google.com/p/librdebug-ruby/'

	s.signing_key = ENV['GEM_PRIVATE_KEY']
	s.cert_chain  = ENV['GEM_CERTIFICATE_CHAIN']

	s.name = 'rdebug'
	s.version = '0.1'
	s.summary = 'A simple debug library for ruby'
	s.description = 'A simple debug library for ruby.'

	s.required_ruby_version = '>= 1.8.1'

	s.require_paths = ['lib']
	s.files = FileList[
		"lib/rdebug/*.rb", 
		"lib/rdebug/render/*.rb", 
		"examples/*.rb", 
		"test/**/*"
	].to_a + [ \
		"Makefile",
		"rdebug.gemspec",
		"COPYING",
		"README"
	]
	s.files.reject! { |fn| fn.include? "coverage" }

	puts "== GEM CONTENT =="
	puts s.files
	puts "== /GEM CONTENT =="
end
