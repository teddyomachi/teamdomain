module Sourcerer
  module Helpers
    class << self

      def scan_count_by str,*args

        counter= 0
        args.each do |sym|
          sym= /\b#{sym}\b/ unless sym.class <= Regexp
          counter += str.scan(sym).count
        end
        return counter

      end

    end
  end
end