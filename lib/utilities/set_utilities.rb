module SetUtility
  ARITH_GT = 1
  ARITH_GE = 2
  ARITH_EQ = 3
  ARITH_LT = 4
  ARITH_LE = 5

  class SetOp
    def self.is_in_set val, dom
      # val : value, :dom => domain array
      domr = [ val ]
      
      domx = domr & dom
      
      if domx.blank?
        return false
      else
        return true
      end

#      if dom == nil or dom.length == 0
#        return false
#      end
#      dom.each { |d|
#        if val == d
#          return true
#        end
#      }
#      return false
    end # enf of is_in_set
  
    def self.is_subset_of s, dom
      # :s => subset, :dom => domain array
      # => returns array of common elements or nil 
      if dom == nil or dom.length == 0
        return false
      end
      ss = s & dom   # => empty ?
      if ss.blank?
        return false
      else
        return true
      end
    end
  
    def compare_elements reg, qt, val
      reg.each { |r|
        case qt
        when ARITH_GT
          if r > val
            return true
          end
        when ARITH_GE
          if r >= val
            return true
          end
        when ARITH_EQ
          if r == val
            return true
          end
        when ARITH_LT
          if r < val
            return true
          end
        when ARITH_LE
          if r <= val
            return true
          end
        else # => never!
          # => do nothing becuase no one can be here.
        end
      }
      return false
    end
  end # => end of SetOp class
  
  def make_set(x,y,z)
    return [x,y,z]
  end
end