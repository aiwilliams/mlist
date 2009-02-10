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
      
      BRACKETS_RE = /\A<(.*?)>\Z/
      def bracket(string)
        string.blank? || string =~ BRACKETS_RE ? string : "<#{string}>"
      end
      
      def remove_brackets(string)
        string =~ BRACKETS_RE ? $1 : string
      end
      
      REGARD_RE = /(^|[^\w])re: /i
      def remove_regard(string)
        while string =~ REGARD_RE
          string = string.sub(REGARD_RE, ' ')
        end
        string.strip
      end
      
      def text_to_html(text)
        lines = normalize_new_lines(text).split("\n")
        lines.collect! do |line|
          line = escape_once(line)
          line = ("&nbsp;" * $1.length) + $2 if line =~ /^(\s+)(.*?)$/
          line = %{<span class="quote">#{line}</span>} if line =~ /^(&gt;|[|]|[A-Za-z]+&gt;)/
          line = line.gsub(/\s\s/, ' &nbsp;')
          line
        end
        lines.join("<br />\n")
      end
      
      def text_to_quoted(text)
        lines = normalize_new_lines(text).split("\n")
        lines.collect! do |line|
          '> ' + line
        end
        lines.join("\n")
      end
      
      HTML_ESCAPE = { '&' => '&amp;',  '>' => '&gt;',   '<' => '&lt;', '"' => '&quot;' }
      def escape_once(text)
        text.gsub(/[\"><]|&(?!([a-zA-Z]+|(#\d+));)/) { |special| HTML_ESCAPE[special] }
      end
    end
    
  end
end