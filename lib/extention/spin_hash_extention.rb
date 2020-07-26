#module SpinHashExtention
#  
  class Hash
    
    def method_missing(method, *params)
      method_string = method.to_s
      if method_string.last == "="
        self[method_string[0..-2]] = params.first
      else
        self[method_string]
      end
    end # => end of method_missing
    
  end # => end of Hash (extention)
  
#end # => end of SpinHashExtention module
