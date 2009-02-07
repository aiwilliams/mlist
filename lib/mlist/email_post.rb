module MList
  
  # The simplest post that can be made to an MList::MailList. Every instance
  # must have at least the text content and a subject. Html may also be added.
  #
  # It is important to understand that this class is intended to be used by
  # applications that have some kind of UI for creating a post. It assumes
  # Rails form builder support is desired, and that there is no need for
  # manipulating the final TMail::Mail object that will be delivered to the
  # list outside of the methods provided herein.
  #
  class EmailPost
    include MList::Util::EmailHelpers
    
    ATTRIBUTE_NAMES = %w(html text mailer subject subscriber)
    ATTRIBUTE_NAMES.each do |attribute_name|
      define_method(attribute_name) do
        @attributes[attribute_name]
      end
      define_method("#{attribute_name}=") do |value|
        @attributes[attribute_name] = value
      end
    end
    
    attr_reader :parent_identifier, :reply_to_message
    
    def initialize(attributes)
      @attributes = {}
      self.attributes = {
        :mailer => 'MList Client Application'
      }.merge(attributes)
    end
    
    def attributes
      @attributes.dup
    end
    
    def attributes=(new_attributes)
      return if new_attributes.nil?
      attributes = new_attributes.dup
      attributes.stringify_keys!
      attributes.each do |attribute_name, value|
        send("#{attribute_name}=", value)
      end
    end
    
    def reply_to_message=(message)
      if message
        @parent_identifier = message.identifier
      else
        @parent_identifier = nil
      end
      @reply_to_message = message
    end
    
    def subject
      @attributes['subject'] || (reply_to_message ? "Re: #{reply_to_message.subject}" : nil)
    end
    
    def to_tmail
      raise ActiveRecord::RecordInvalid.new(self) unless valid?
      
      builder = MList::Util::TMailBuilder.new(TMail::Mail.new)
      
      builder.mime_version = "1.0"
      builder.mailer = mailer
      
      if parent_identifier
        builder.in_reply_to = parent_identifier
        builder.references = [bracket(parent_identifier)]
      end
      
      from = subscriber.email_address
      from = "#{subscriber.display_name} #{bracket(from)}" if subscriber.respond_to?(:display_name)
      builder.from = from
      
      builder.subject = subject
      
      if html
        builder.add_text_part(text)
        builder.add_html_part(html)
        builder.set_content_type('multipart/alternative')
      else
        builder.body = text
        builder.set_content_type('text/plain')
      end
      
      builder.tmail
    end
    
    # vvv  ActiveRecord validations interface implementation  vvv
    
    def self.human_attribute_name(attribute_key_name, options = {})
      attribute_key_name.humanize
    end
    
    def errors
      @errors ||= ActiveRecord::Errors.new(self)
    end
    
    def validate
      errors.clear
      errors.add(:subject, 'required') if subject.blank?
      errors.add(:text, 'required') if text.blank?
      errors.add(:text, 'needs to be a bit longer') if !text.blank? && text.strip.size < 25
      errors.empty?
    end
    
    def valid?
      validate
    end
  end
end