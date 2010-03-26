module MList
  module Util

    class HtmlTextExtraction

      # We need a way to maintain non-breaking spaces. Hpricot will replace
      # them with ??.chr. We can easily teach it to convert it to a space, but
      # then we lose the information in the Text node that we need to keep the
      # space around, since that is what they would see in a view of the HTML.
      NBSP = '!!!NBSP!!!'

      def initialize(html)
        @doc = Hpricot(html.gsub('&nbsp;', NBSP))
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
        @text.gsub(NBSP, ' ')
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

      def subscriber_name_and_address(subscriber)
        a = subscriber.email_address
        a = "#{subscriber.display_name} #{bracket(a)}" if subscriber.respond_to?(:display_name)
        a
      end

      AUTO_LINK_RE = %r{
          ( https?:// | www\. )
          [^\s<]+
        }x unless const_defined?(:AUTO_LINK_RE)

      BRACKETS = { ']' => '[', ')' => '(', '}' => '{' }

      # Turns all urls into clickable links.  If a block is given, each url
      # is yielded and the result is used as the link text.
      def auto_link_urls(text)
        text.gsub(AUTO_LINK_RE) do
          href = $&
          punctuation = ''
          left, right = $`, $'
          # detect already linked URLs and URLs in the middle of a tag
          if left =~ /<[^>]+$/ && right =~ /^[^>]*>/
            # do not change string; URL is alreay linked
            href
          else
            # don't include trailing punctuation character as part of the URL
            if href.sub!(/[^\w\/-]$/, '') and punctuation = $& and opening = BRACKETS[punctuation]
              if href.scan(opening).size > href.scan(punctuation).size
                href << punctuation
                punctuation = ''
              end
            end

            link_text = block_given?? yield(href) : href
            href = 'http://' + href unless href.index('http') == 0

            %Q(<a href="#{href}">#{link_text}</a>)
          end
        end
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
