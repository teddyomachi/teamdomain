#!/usr/bin/ruby

class Object
	def __function__
		caller[0] =~ /\d:in `([^']+)'/
			$1
	end

	def rdebug *args
		caller_method = nil
		if caller[0] =~ /\d:in `([^']+)'/ then
			caller_method = $1.strip
		end

		if self.instance_variables.include? "@debug" and @debug then
			STDERR.print "%s::%s - %s\n" % [ self.class, caller_method, args ]
		end
	end
end 

