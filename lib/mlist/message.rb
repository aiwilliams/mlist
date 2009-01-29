module MList
  
  # The persisted version of an email that is processed by MList::MailLists.
  #
  # The tmail object referenced by these are unique, though they may reference
  # the 'same' originating email.
  #
  class Message < ActiveRecord::Base
    set_table_name 'mlist_messages'
    
    belongs_to :mail_list, :class_name => 'MList::MailList'
    
    attr_writer :header_sanitizers
    before_save :serialize_tmail
    
    def charset
      'utf-8'
    end
    
    def delete_header(name)
      tmail[name] = nil
    end
    
    def from_address
      tmail.from.first
    end
    
    def parent_identifier
      if in_reply_to = header_string('in-reply-to')
        identifier = in_reply_to
      elsif references = read_header('references')
        identifier = references.ids.first
      else
        parent_message = mail_list.messages.find(:first,
          :conditions => ['mlist_messages.subject = ?', remove_regard(subject)],
          :order => 'created_at asc'
        )
        identifier = parent_message.identifier if parent_message
      end
      remove_brackets(identifier) if identifier
    end
    
    def read_header(name)
      tmail[name]
    end
    
    def reply?
      !parent_identifier.nil?
    end
    
    # Add another value for the named header, it's position being earlier in
    # the email than those that are already present. This will raise an error
    # if the header does not allow multiple values according to
    # TMail::Mail::ALLOW_MULTIPLE.
    #
    def prepend_header(name, value)
      original = tmail[name] || []
      tmail[name] = nil
      tmail[name] = sanitize_header(name, value)
      tmail[name] = tmail[name] + original
    end
    
    def write_header(name, value)
      tmail[name] = sanitize_header(name, value)
    end
    
    def tmail=(tmail)
      write_attribute(:identifier, remove_brackets(tmail.header_string('message-id')))
      write_attribute(:subject, tmail.subject)
      @tmail = tmail
    end
    
    def tmail
      @tmail ||= TMail::Mail.parse(email_text)
    end
    
    def to=(recipient_addresses)
      tmail.to = sanitize_header('to', recipient_addresses)
    end
    
    def bcc=(recipient_addresses)
      tmail.bcc = sanitize_header('bcc', recipient_addresses)
    end
    
    # Provide delegation to *most* of the underlying TMail::Mail methods,
    # excluding those overridden by this class and the [] and []= methods. We
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
    
    def sanitize_header(name, *values)
      header_sanitizer(name).call(charset, *values)
    end
    
    def subscriber
      @subscriber ||= begin
        if subscriber_type? && subscriber_id?
          subscriber_type.constantize.find(subscriber_id)
        elsif subscriber_address?
          MList::EmailSubscriber.new(subscriber_address)
        end
      end
    end
    
    def subscriber=(subscriber)
      case subscriber
      when ActiveRecord::Base
        @subscriber = subscriber
        self.subscriber_address = subscriber.email_address
        self.subscriber_type = subscriber.class.base_class.name
        self.subscriber_id = subscriber.id
      when MList::EmailSubscriber
        @subscriber = subscriber
        self.subscriber_address = subscriber.email_address
        self.subscriber_type = self.subscriber_id = nil
      when String
        self.subscriber = MList::EmailSubscriber.new(subscriber)
      else
        @subscriber = self.subscriber_address = self.subscriber_type = self.subscriber_id = nil
      end
    end
    
    private
      def header_sanitizer(name)
        @header_sanitizers ||= Util.default_header_sanitizers
        @header_sanitizers[name]
      end
      
      def remove_brackets(string)
        string =~ /\A<(.*?)>\Z/ ? $1 : string
      end
      
      def remove_regard(string)
        stripped = string.strip
        stripped =~ /\A.*re:\s+(\[.*\]\s*)?(.*?)\Z/i ? $2 : stripped
      end
      
      def serialize_tmail
        write_attribute(:email_text, @tmail.to_s)
      end
  end
end