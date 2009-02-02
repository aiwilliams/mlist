module MList
  module Util
    
    class TMailAdapter
      include TMailMethods
      
      def initialize(tmail)
        @tmail = tmail
      end
      
      def add_html_part(body)
        part = TMail::Mail.new
        part.body = normalize_new_lines(body)
        part.set_content_type('text/html')
        self.parts << part
      end
      
      def add_text_part(body)
        part = TMail::Mail.new
        part.body = normalize_new_lines(body)
        part.set_content_type('text/plain')
        self.parts << part
      end
    end
    
  end
end