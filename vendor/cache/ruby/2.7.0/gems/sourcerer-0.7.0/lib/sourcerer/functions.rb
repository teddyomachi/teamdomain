module Sourcerer

  EXT= Module.new
  module EXT::SourceLocation

    #> return a proc source code
    def source

        var= self.source_location.map{|obj| obj.class <= String ? File.absolute_path(obj) : obj }

        file_obj= File.open(var[0],"r")
        file_data= [] #> [*File.open(var[0],"r")]
        (var[1] - 1).times{ file_obj.gets }

        tags= 0
        loop {

          file_data.push(file_obj.gets.chomp)
          new_string_line= file_data.last

          tags += ::Sourcerer::Helpers.scan_count_by new_string_line, /\{/,:def,:do,:if,:unless,:loop,:while,:until
          tags -= ::Sourcerer::Helpers.scan_count_by new_string_line, /\}/,:end

          break if tags <= 0
          break if file_data.last.nil?

        }

        self_obj= file_data.join("\n")
        self_obj.gsub!(";","\n") unless %W[ ' " ].map!{|str| self_obj.include?(str) }.include?(true)

        first_line= self_obj
        case true

          when first_line.include?('Proc')
            self_obj.sub!(/^[\w =]*Proc.new\s*{ */,'Proc.new { ')

          when first_line.include?('lambda')
            self_obj.sub!(/^[\w =]*lambda\s*{ */,'Proc.new { ')

          when first_line.include?('def'),first_line.include?('Method')
            the_params= self_obj.scan(/ *def *[\w\.]*[\( ] *(.*)/)[0][0]
            self_obj.sub!(
                self_obj.split("\n")[0],
                "Proc.new { |#{the_params}|"
            )

            replace_obj= self_obj.split("\n")
            var= replace_obj.last.reverse.sub( /\bdne\b/,"-AAAAAAAAAAAA-").reverse.sub("-AAAAAAAAAAAA-","}")
            replace_obj.pop
            replace_obj.push(var)
            self_obj.replace replace_obj.join("\n")


        end


        return ::Sourcerer::SourceCode.new(self_obj)

    end

  end


end

[Method,UnboundMethod,Proc].each{ |cls| cls.__send__(:include,Sourcerer::EXT::SourceLocation) }