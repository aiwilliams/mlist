module MList
  
  # The simplest post that can be made to an MList::MailList. Every instance
  # must have at least the text content. Html may also be added.
  #
  class EmailPost
    include MList::Util::TMailMethods
    
    attr_reader :subscriber, :reply_to
    
    # :subject - required unless :reply_to message given
    # :text    - required
    #
    def initialize(attributes)
      @tmail = TMail::Mail.new
      
      self.mime_version = "1.0"
      
      self.mailer = attributes[:mailer] || 'MList Client Application'
      self.subscriber = attributes[:subscriber]
      self.reply_to = attributes[:reply_to]
      self.subject = attributes[:subject] ||= "Re: #{@reply_to.subject}"
      
      if attributes[:html]
        add_text_part(attributes[:text])
        add_html_part(attributes[:html])
        self.set_content_type('multipart/alternative')
      else
        self.body = attributes[:text]
        self.set_content_type('text/plain')
      end
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
    
    def mailer=(mailer)
      self.write_header('x-mailer', mailer)
    end
    
    def parent_identifier
      @reply_to ? @reply_to.identifier : nil
    end
    
    def reply_to=(message)
      message.reset if message
      @reply_to = message
    end
    
    def subscriber=(subscriber)
      self.from = subscriber ? subscriber.email_address : nil
      @subscriber = subscriber
    end
  end
end