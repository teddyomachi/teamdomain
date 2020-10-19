TESTS=$(wildcard *.rb)

all: test-unit test-notimplemented

test-unit-%: %.rb
	rcov --aggregate coverage/cov.info $< 2>&1 >/dev/null
	ruby $< || exit 1

test-unit:
	# 
	# UNIT TESTING
	#
	echo "require 'test/unit'" > coverage.rb
	echo "\$$LOAD_PATH.insert( 0, '../lib' )" >> coverage.rb
	find ../lib/ |grep rb$$ |sed -e 's/.rb$$/"/' -e 's|../lib/||' -e 's/^/require "/' >> coverage.rb
	#
	rm -fr coverage
	mkdir -p coverage
	for test in $(TESTS); do \
		$(MAKE) test-unit-$${test/.rb/} ; \
	done
	#
	# TESTING MISSING CODE
	#

test-notimplemented:
	TMP=`mktemp` ; \
		find ../lib -name '*.rb' |xargs grep -n 'NotImplementedError' > $$TMP ; \
		COUNT=`wc -l < $$TMP` ; \
		if [ $$COUNT -gt 0 ]; then \
		cat $$TMP 1>&2 ; \
		fi

clean:
	rm -fr coverage
	rm -f coverage.rb
