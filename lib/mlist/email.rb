module MList
  
  class Email < ActiveRecord::Base
    set_table_name 'mlist_emails'
    
    include MList::Util::EmailHelpers
    include MList::Util::TMailReaders
    
    def been_here?(list)
      tmail.header_string('x-beenthere') == list.address
    end
    
    def from
      tmail.header_string('from')
    end
    
    # Answers the usable destination addresses of the email.
    #
    def list_addresses
      bounce? ? tmail.header_string('to').match(/\Amlist-(.*)\Z/)[1] : tmail.to.collect(&:downcase)
    end
    
    # Answers true if this email is a bounce.
    #
    # TODO Delegate to the email_server's bounce detector.
    #
    def bounce?
      tmail.header_string('to') =~ /mlist-/
    end
    
    # Extracts the parent message identifier from the source, using
    # in-reply-to first, then references. Brackets around the identifier are
    # removed.
    #
    # If you provide an MList::MailList, it will be searched for a message
    # having the same subject as a last resort.
    #
    def parent_identifier(mail_list = nil)
      identifier = tmail.header_string('in-reply-to') || begin
        references = tmail['references']
        references.ids.first if references
      end
      
      if identifier
        remove_brackets(identifier)
      elsif mail_list && subject =~ /(^|[^\w])re:/i
        parent_message = mail_list.messages.find(:first,
          :select => 'identifier',
          :conditions => ['mlist_messages.subject = ?', remove_regard(subject)],
          :order => 'created_at asc')
        parent_message.identifier if parent_message
      end
    end
    
    def subject
      tmail.subject
    end
    
    def tmail=(tmail)
      @tmail = tmail
      write_attribute(:source, tmail.to_s)
    end
    
    def tmail
      @tmail ||= TMail::Mail.parse(source)
    end
    
    # Provide reader delegation to *most* of the underlying TMail::Mail
    # methods, excluding those overridden by this Class and the [] method (an
    # ActiveRecord method).
    #
    def method_missing(symbol, *args, &block) # :nodoc:
      if symbol.to_s !~ /=\Z/ && tmail.respond_to?(symbol) && symbol != :[]
        @tmail.__send__(symbol, *args, &block)
      else
        super
      end
    end
  end
end