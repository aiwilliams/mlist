module MList
  
  class Message < ActiveRecord::Base
    set_table_name 'mlist_messages'
    
    include MList::Util::EmailHelpers
    
    belongs_to :email, :class_name => 'MList::Email'
    belongs_to :parent, :class_name => 'MList::Message'
    belongs_to :mail_list, :class_name => 'MList::MailList', :counter_cache => :messages_count
    belongs_to :thread, :class_name => 'MList::Thread', :counter_cache => :messages_count
    
    after_destroy :delete_unreferenced_email
    
    # A temporary storage of recipient subscribers, obtained from
    # MList::Lists. This list is not available when a message is reloaded.
    #
    attr_accessor :recipients
    
    # Answers an MList::TMailBuilder for assembling the TMail::Mail object
    # that will be fit for delivery. If this is not a new message, the
    # delivery will be updated to reflect the message-id, x-mailer, etc. of
    # this message.
    #
    def delivery
      @delivery ||= begin
        d = MList::Util::TMailBuilder.new(TMail::Mail.parse(email.source))
        unless new_record?
          d.message_id = self.identifier
          d.mailer = self.mailer
          d.date = self.created_at
        end
        d
      end
    end
    
    def email_with_capture=(email)
      self.subject = email.subject
      self.mailer = email.mailer
      self.email_without_capture = email
    end
    alias_method_chain :email=, :capture
    
    # Answers the html content of the message.
    #
    def html
      email.html
    end
    
    # Answers the text content of the message.
    #
    def text
      email.text
    end
    
    # Answers the text content of the message as HTML. The structure of this
    # output is very simple. For examples of what it can handle, please check
    # out the spec documents for MList::Util::EmailHelpers.
    #
    def text_html
      text_to_html(text)
    end
    
    # Answers text suitable for creating a reply message.
    #
    def text_for_reply
      timestamp = email.date.to_s(:mlist_reply_timestamp)
      "On #{timestamp}, #{email.from} wrote:\n#{text_to_quoted(text)}"
    end
    
    # Answers text suitable for creating a reply message, converted to the
    # same simple html of _text_html_.
    #
    def html_for_reply
      text_to_html(text_for_reply)
    end
    
    def parent_with_identifier_capture=(parent)
      if parent
        self.parent_without_identifier_capture = parent
        self.parent_identifier = parent.identifier
      else
        self.parent_without_identifier_capture = nil
        self.parent_identifier = nil
      end
    end
    alias_method_chain :parent=, :identifier_capture
    
    # Answers the recipient email addresses from the MList::List recipient
    # subscribers, except those that are in the email TO or CC fields as
    # placed there by the sending MUA. It is assumed that those addresses have
    # received a copy of the email already, and that by including them here,
    # we would cause them to receive two copies of the message.
    #
    def recipient_addresses
      @recipients.collect(&:email_address).collect(&:downcase) - email.recipient_addresses
    end
    
    # Answers the subject with 'Re:' prefixed. Note that it is the
    # responsibility of the MList::MailList to perform any processing of the
    # persisted subject (ie, cleaning up labels, etc).
    #
    #   message.subject = '[List Label] Re: The new Chrome Browser from Google'
    #   message.subject_for_reply   => 'Re: [List Label] The new Chrome Browser from Google'
    #
    #   message.subject = 'Re: [List Label] Re: The new Chrome Browser from Google'
    #   message.subject_for_reply   => 'Re: [List Label] The new Chrome Browser from Google'
    #
    def subject_for_reply
      subject =~ REGARD_RE ? subject : "Re: #{subject}"
    end
    
    # Answers the subscriber from which this message comes.
    #
    def subscriber
      @subscriber ||= begin
        if subscriber_type? && subscriber_id?
          subscriber_type.constantize.find(subscriber_id)
        elsif subscriber_address?
          MList::EmailSubscriber.new(subscriber_address)
        end
      end
    end
    
    # Assigns the subscriber from which this message comes.
    #
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
      def delete_unreferenced_email
        email.destroy unless MList::Message.count(:conditions => "email_id = #{email_id} and id != #{id}") > 0
      end
  end
end