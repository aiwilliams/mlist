module MList
  
  # The persisted version of an email that is processed by MList::Lists.
  #
  # The tmail object referenced by these are unique, though they may reference
  # the 'same' originating email.
  #
  class Mail < ActiveRecord::Base
    attr_writer :header_sanitizers
    
    before_save :serialize_tmail
    
    def charset
      'utf-8'
    end
    
    def read_header(name)
      tmail[name]
    end
    
    def write_header(name, value)
      tmail[name] = sanitize_header(name, value)
    end
    
    def tmail=(tmail)
      @tmail = tmail
    end
    
    def tmail
      @tmail ||= TMail::Mail.parse(email_text)
    end
    
    def to=(recipients)
      tmail.to = sanitize_header('to', recipients)
    end
    
    def bcc=(recipients)
      tmail.bcc = sanitize_header('bcc', recipients)
    end
    
    def method_missing(symbol, *args, &block)
      tmail.__send__(symbol, *args, &block)
    end
    
    def sanitize_header(name, *values)
      header_sanitizer(name).call(charset, *values)
    end
    
    private
      def header_sanitizer(name)
        @header_sanitizers ||= Util.default_header_sanitizers
        @header_sanitizers[name]
      end
      
      def serialize_tmail
        write_attribute(:email_text, @tmail.to_s)
      end
  end
end