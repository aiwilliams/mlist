module MList
  class MailList < ActiveRecord::Base
    set_table_name 'mlist_mail_lists'
    
    # Provides the MailList for a given implementation of MList::List,
    # connecting it to the provided email server for delivering posts.
    #
    def self.find_or_create_by_list(list, outgoing_server)
      if list.is_a?(ActiveRecord::Base)
        mail_list = find_or_create_by_manager_list_identifier_and_manager_list_type_and_manager_list_id(
          list.list_id, list.class.base_class.name, list.id
        )
      else
        mail_list = find_or_create_by_manager_list_identifier(list.list_id)
        mail_list.manager_list = list
      end
      mail_list.outgoing_server = outgoing_server
      mail_list
    end
    
    belongs_to :manager_list, :polymorphic => true
    
    has_many :messages, :class_name => 'MList::Message', :dependent => :delete_all
    has_many :threads, :class_name => 'MList::Thread', :dependent => :delete_all
    
    delegate :address, :label, :post_url, :to => :list
    
    attr_accessor :outgoing_server
    
    # Creates a new MList::Message and delivers it to the subscribers of this
    # list.
    #
    def post(email_or_attributes)
      email = email_or_attributes
      email = MList::EmailPost.new(email_or_attributes) unless email.is_a?(MList::EmailPost)
      process_message messages.build(
        :parent => email.reply_to_message,
        :parent_identifier => email.parent_identifier,
        :mail_list => self,
        :subscriber => email.subscriber,
        :recipients => list.recipients(email.subscriber),
        :email => MList::Email.new(:tmail => email.to_tmail)
      ), :search_parent => false
    end
    
    # Processes the email received by the MList::Server.
    #
    def process_email(email)
      subscriber = list.subscriber(email.from_address)
      recipients = list.recipients(subscriber)
      process_message messages.build(
        :mail_list => self,
        :subscriber => subscriber,
        :recipients => recipients,
        :email => email
      )
    end
    
    def list
      @list ||= manager_list
    end
    
    def manager_list_with_dual_type=(list)
      if list.is_a?(ActiveRecord::Base)
        self.manager_list_without_dual_type = list
        @list = list
      else
        self.manager_list_without_dual_type = nil
        @list = list
      end
    end
    alias_method_chain :manager_list=, :dual_type
    
    def process?(message)
      !message.recipients.blank?
    end
    
    private
      # http://mail.python.org/pipermail/mailman-developers/2006-April/018718.html
      def bounce_headers
        {'sender'    => "mlist-#{address}",
         'errors-to' => "mlist-#{address}"}
      end
      
      # http://www.jamesshuggins.com/h/web1/list-email-headers.htm
      def list_headers
        headers = list.list_headers
        headers['x-beenthere'] = address
        headers.update(bounce_headers)
        headers.delete_if {|k,v| v.nil?}
      end
      
      def process_message(message, options = {})
        raise MList::DoubleDeliveryError.new(message) unless message.new_record?
        return message unless process?(message)
        
        options = {
          :search_parent => true,
          :delivery_time => Time.now
        }.merge(options)
        
        transaction do
          thread = find_thread(message, options)
          thread.updated_at = options[:delivery_time]
          
          delivery = prepare_delivery(message, options)
          thread.messages << message
          
          self.updated_at = options[:delivery_time]
          thread.save! && save!
          
          outgoing_server.deliver(delivery.tmail)
        end
        
        message
      end
      
      def prepare_delivery(message, options)
        message.identifier = outgoing_server.generate_message_id
        message.created_at = options[:delivery_time]
        returning(message.delivery) do |delivery|
          delivery.date = message.created_at
          delivery.message_id = message.identifier
          delivery.mailer = message.mailer
          delivery.headers = list_headers
          delivery.subject = list_subject(message)
          delivery.to = address
          delivery.bcc = message.recipients.collect(&:email_address)
          delivery.reply_to = "#{label} <#{post_url}>"
        end
      end
      
      def list_subject(message)
        prefix = "[#{label}]"
        subject = message.subject.gsub(%r(#{Regexp.escape(prefix)}\s*), '')
        subject.gsub!(%r{(re:\s*){2,}}i, 'Re: ')
        "#{prefix} #{subject}"
      end
      
      def find_thread(message, options)
        if options[:search_parent]
          message.parent_identifier = message.email.parent_identifier(self)
          message.parent = messages.find_by_identifier(message.parent_identifier)
        end
        message.parent ? message.parent.thread : threads.build
      end
  end
end