module Sourcerer
  class SourceCode < String

    def parameters
      @parameters || self.dismantle.parameters
    end
    alias :args   :parameters
    alias :params :parameters

    def body
      @body || self.dismantle.body
    end

    def dismantle

      self_dup= self.dup

      #TODO: optionable args search for comments
      parameters_var=  self.scan(/\s*Proc\.new\s*{\s*\|(.*)\|/)
      if parameters_var.empty?
        @parameters= ""
      else
        @parameters= parameters_var[0][0]
        self_dup.sub!(parameters_var[0][0],"")
        self_dup.sub!( self_dup.split("\n")[0], self_dup.split("\n")[0].gsub("|","") )
      end

      self_dup.slice! /\s*Proc\.new\s*{[\s\n]*/
      self_dup[self_dup.length-1]=""

      @body= self_dup

      return self

    end

  end
end