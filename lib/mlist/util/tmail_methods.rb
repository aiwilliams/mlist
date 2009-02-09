module MList
  module Util
    
    module TMailReaders
      def date
        if date = tmail.header_string('date')
          Time.parse(date)
        else
          self.created_at ||= Time.now
        end
      end
      
      def from_address
        tmail.from.first.downcase
      end
      
      def html
        case tmail.content_type
        when 'text/html'
          tmail.body.strip
        when 'multipart/alternative'
          text_part = tmail.parts.detect {|part| part.content_type == 'text/html'}
          text_part.body.strip if text_part
        end
      end
      
      def identifier
        remove_brackets(tmail.header_string('message-id'))
      end
      
      def mailer
        tmail.header_string('x-mailer')
      end
      
      def text
        returning('') {|content| extract_text_content(tmail, content)}
      end
      
      private
        def extract_text_content(part, collector)
          case part.content_type
          when 'text/plain'
            collector << part.body.strip
          when 'multipart/alternative'
            text_part = part.parts.detect {|part| part.content_type == 'text/plain'}
            collector << text_part.body.strip if text_part
          when 'multipart/mixed', 'multipart/related'
            part.parts.each {|mixed_part| extract_text_content(mixed_part, collector)}
          end
        end
    end
    
    module TMailWriters
      def charset
        'utf-8'
      end
      
      def delete_header(name)
        tmail[name] = nil
      end
      
      def headers=(updates)
        updates.each do |k,v|
          if TMail::Mail::ALLOW_MULTIPLE.include?(k.downcase)
            prepend_header(k,v)
          else
            write_header(k,v)
          end
        end
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
      
      def mailer=(value)
        write_header('x-mailer', value)
      end
      
      def message_id=(value)
        tmail.message_id = sanitize_header(charset, 'message-id', value)
      end
    end
    
  end
end