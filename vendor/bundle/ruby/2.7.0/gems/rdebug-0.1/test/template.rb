
# create sample system command

# exec system command

# verify return code

# run batch and catch errors


require "test/unit"

$LOAD_PATH.insert( 0, '../lib' )

require 'rdebug/base'

class TestXyz < Test::Unit::TestCase

	def test_base
		#assert_nothing_raised( Exception ) do
		#	sc.run
		#end

		#assert_raise( CommandRuntimeError ) do
		#	sc.run
		#end

	end

end

