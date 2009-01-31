module MList
  module Util
    
    module EmailHelpers
      def sanitize_header(charset, name, *values)
        header_sanitizer(name).call(charset, *values)
      end
      
      def header_sanitizer(name)
        Util.default_header_sanitizers[name]
      end
      
      def normalize_new_lines(text)
        text.to_s.gsub(/\r\n?/, "\n")
      end
      
      def remove_brackets(string)
        string =~ /\A<(.*?)>\Z/ ? $1 : string
      end
      
      def remove_regard(string)
        stripped = string.strip
        stripped =~ /\A.*re:\s+(\[.*\]\s*)?(.*?)\Z/i ? $2 : stripped
      end
    end
    
  end
end