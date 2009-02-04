module MList
  module Util
    
    class TMailBuilder
      include EmailHelpers
      include TMailReaders
      include TMailWriters
      
      attr_reader :tmail
      
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
      
      # Provide delegation to *most* of the underlying TMail::Mail methods,
      # excluding those overridden by this Module.
      #
      def method_missing(symbol, *args, &block) # :nodoc:
        if tmail.respond_to?(symbol)
          tmail.__send__(symbol, *args, &block)
        else
          super
        end
      end
    end
    
  end
end