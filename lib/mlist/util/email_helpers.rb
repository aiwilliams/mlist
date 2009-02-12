module MList
  module Util
    
    class HtmlTextExtraction
      def initialize(html)
        @doc = Hpricot(html)
      end
      
      def execute
        @text, @anchors = '', []
        @doc.each_child do |node|
          extract_text_from_node(node) if Hpricot::Elem::Trav === node
        end
        @text.strip!
        unless @anchors.empty?
          refs = []
          @anchors.each_with_index do |href, i|
            refs << "[#{i+1}] #{href}"
          end
          @text << "\n\n--\n#{refs.join("\n")}"
        end
        @text
      end
      
      def extract_text_from_node(node)
        case node.name
        when 'head'
        when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
          @text << node.inner_text
          @text << "\n\n"
        when 'br'
          @text << "\n"
        when 'ol'
          node.children_of_type('li').each_with_index do |li, i|
            @text << " #{i+1}. #{li.inner_text}"
            @text << "\n\n"
          end
        when 'ul'
          node.children_of_type('li').each do |li|
            @text << " * #{li.inner_text.strip}"
            @text << "\n\n"
          end
        when 'strong'
          @text << "*#{node.inner_text}*"
        when 'em'
          @text << "_#{node.inner_text}_"
        when 'dl'
          node.traverse_element('dt', 'dd') do |dt_dd|
            extract_text_from_node(dt_dd)
          end
        when 'a'
          @anchors << node['href']
          extract_text_from_text_node(node)
          @text << "[#{@anchors.size}]"
        when 'p', 'dt', 'dd'
          extract_text_from_children(node)
          @text.rstrip!
          @text << "\n\n"
        else
          extract_text_from_children(node)
        end
      end
      
      def extract_text_from_children(elem)
        elem.each_child do |node|
          case node
          when Hpricot::Text::Trav
            extract_text_from_text_node(node)
          when Hpricot::Elem::Trav
            extract_text_from_node(node)
          end
        end
      end
      
      def extract_text_from_text_node(node)
        text = @text.end_with?("\n") ? node.inner_text.lstrip : node.inner_text
        @text << text.gsub(/\s{2,}/, ' ').sub(/\n/, '')
      end
    end
    
    module EmailHelpers
      def sanitize_header(charset, name, *values)
        header_sanitizer(name).call(charset, *values)
      end
      
      def header_sanitizer(name)
        Util.default_header_sanitizers[name]
      end
      
      def html_to_text(html)
        HtmlTextExtraction.new(html).execute
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