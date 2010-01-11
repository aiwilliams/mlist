module MList
  
  class Email < ActiveRecord::Base
    set_table_name 'mlist_emails'
    
    include MList::Util::EmailHelpers
    include MList::Util::TMailReaders
    
    def date
      if date_from_email = super
        return date_from_email
      else
        self.created_at ||= Time.now
      end
    end
    
    def from
      tmail.header_string('from')
    end
    
    # Answers the values of all the X-BeenThere headers.
    #
    def been_there_addresses
      Array(tmail['x-beenthere']).collect { |e| e.body.downcase }.uniq
    end
    
    # Answers the usable destination addresses of the email.
    #
    def list_addresses
      bounce? ? tmail.header_string('to').match(/\Amlist-(.*)\Z/)[1] : recipient_addresses
    end
    
    # Answers true if this email is a bounce.
    #
    # TODO Delegate to the email_server's bounce detector.
    #
    def bounce?
      tmail.header_string('to') =~ /mlist-/
    end
    
    def tmail=(tmail)
      @tmail = tmail
      write_attribute(:source, tmail.port.read_all)
    end
    
    def tmail
      @tmail ||= TMail::Mail.parse(source)
    end
    
    # Provide reader delegation to *most* of the underlying TMail::Mail
    # methods, excluding those overridden by this Class and the [] method (an
    # ActiveRecord method).
    def method_missing(symbol, *args, &block) # :nodoc:
      if symbol.to_s !~ /=\Z/ && symbol != :[] && symbol != :source && tmail.respond_to?(symbol)
        tmail.__send__(symbol, *args, &block)
      else
        super
      end
    end
    
    # Answers the set of addresses found in the TO and CC fields of the email.
    #
    def recipient_addresses
      (Array(tmail.to) + Array(tmail.cc)).collect(&:downcase).uniq
    end
    
    def respond_to?(method)
      super || (method.to_s !~ /=\Z/ && tmail.respond_to?(method))
    end
  end
end