module MList
  
  # The simplest post that can be made to an MList::MailList. Every instance
  # must have at least the text content. Html may also be added.
  #
  class EmailPost
    include MList::Util::TMailMethods
    
    def initialize(attributes)
      @tmail = TMail::Mail.new
      @tmail.mime_version = "1.0"
      @tmail['x-mailer'] = attributes[:mailer] || 'MList Client Application'
      
      self.from = attributes[:subscriber].email_address
      self.subject = attributes[:subject]
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
  end
end