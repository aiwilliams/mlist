module MList
  
  # The persisted version of an email that is processed by MList::MailLists.
  #
  # The tmail object referenced by these are unique, though they may reference
  # the 'same' originating email. It is by design that multiple copies of an
  # email text may exist when it is delivered to more than one list. Until we
  # have a better understanding of whether this happens a lot or no, this
  # simplifies things a bit.
  #
  class Message < ActiveRecord::Base
    set_table_name 'mlist_messages'
    
    include MList::Util::TMailMethods
    
    belongs_to :mail_list, :class_name => 'MList::MailList'
    belongs_to :parent, :class_name => 'MList::Message'
    belongs_to :thread, :class_name => 'MList::Thread'
    
    # Assign the TMail::Mail content that this message will represent. It is
    # important to understand that any modifications made to the TMail::Mail
    # instance answered by this message will not be persistent. The ORIGINAL
    # email content, as received from MUAs, is preserved, whereas
    # modifications are intended for use only during the delivery of the
    # message.
    #
    def tmail=(tmail)
      @tmail = TMail::Mail.parse(write_attribute(:email_text, tmail.to_s))
      write_attribute(:identifier, remove_brackets(@tmail.header_string('message-id')))
      write_attribute(:mailer, extract_mailer)
      write_attribute(:subject, @tmail.subject)
    end
    
    def tmail
      @tmail ||= TMail::Mail.parse(email_text)
    end
    
    # Cause the message to re-parse the email text, thereby forgetting any
    # changes that have been made to the underlying email.
    #
    def reset
      @tmail = TMail::Mail.parse(email_text)
    end
    
    # The subject of the TMail::Mail instance, which may be different from the
    # value of the message received (modified for delivery).
    #
    def subject
      tmail.subject
    end
    
    # Assigns the subject of the TMail::Mail instance. This will not modify
    # the stored value, which is intended to represent the subject as received
    # in the originating email.
    #
    def subject=(value)
      tmail.subject = value
    end
    
    # Answers the subscriber to which this message belongs; the sending list
    # subscriber.
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
    
    # Assigns the subscriber to which this message belongs; the sending list
    # subscriber.
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
      def identifier=(value)
        raise 'modifying the message identifier is not permitted'
      end
  end
end