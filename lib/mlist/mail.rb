module MList
  
  # The persisted version of an email that is processed by MList::Lists.
  #
  # The tmail object referenced by these are unique, though they may reference
  # the 'same' originating email.
  #
  class Mail < ActiveRecord::Base
    before_save :serialize_tmail
    
    def read_header(header_name)
      tmail[header_name]
    end
    
    def write_header(header_name, value)
      tmail[header_name] = value
    end
    
    def tmail=(tmail)
      @tmail = tmail
    end
    
    def tmail
      @tmail ||= TMail::Mail.parse(email_text)
    end
    
    def method_missing(symbol, *args, &block)
      tmail.__send__(symbol, *args, &block)
    end
    
    private
      def serialize_tmail
        write_attribute(:email_text, @tmail.to_s)
      end
  end
end