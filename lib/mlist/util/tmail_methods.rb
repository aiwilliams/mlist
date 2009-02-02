module MList
  module Util
    
    # A module added to classes that wrap a TMail::Mail instance.
    #
    module TMailMethods
      include EmailHelpers
      
      attr_reader :tmail
      
      def charset
        'utf-8'
      end
      
      def delete_header(name)
        tmail[name] = nil
      end
      
      def from_address
        tmail.from.first
      end
      
      def read_header(name)
        tmail[name]
      end
      
      # Add another value for the named header, it's position being earlier in
      # the email than those that are already present. This will raise an error
      # if the header does not allow multiple values according to
      # TMail::Mail::ALLOW_MULTIPLE.
      #
      def prepend_header(name, value)
        original = tmail[name] || []
        tmail[name] = nil
        tmail[name] = sanitize_header(charset, name, value)
        tmail[name] = tmail[name] + original
      end
      
      def write_header(name, value)
        tmail[name] = sanitize_header(charset, name, value)
      end
      
      def to=(recipient_addresses)
        tmail.to = sanitize_header(charset, 'to', recipient_addresses)
      end
      
      def bcc=(recipient_addresses)
        tmail.bcc = sanitize_header(charset, 'bcc', recipient_addresses)
      end
      
      def from=(from_address)
        tmail.from = sanitize_header(charset, 'from', from_address)
      end
      
      def in_reply_to=(*values)
        tmail.in_reply_to = sanitize_header(charset, 'in-reply-to', *values)
      end
      
      # Provide delegation to *most* of the underlying TMail::Mail methods,
      # excluding those overridden by this Module and the [] and []= methods. We
      # must maintain the ActiveRecord interface over that of the TMail::Mail
      # interface.
      #
      def method_missing(symbol, *args, &block) # :nodoc:
        if @tmail && @tmail.respond_to?(symbol) && !(symbol == :[] || symbol == :[]=)
          @tmail.__send__(symbol, *args, &block)
        else
          super
        end
      end
      
      private
        def extract_mailer
          tmail.header_string('x-mailer')
        end
    end
    
  end
end