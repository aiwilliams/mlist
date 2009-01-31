module MList
  class MailList < ActiveRecord::Base
    set_table_name 'mlist_mail_lists'
    
    include MList::Util::EmailHelpers
    
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
    # This API is provided for applications that want the simplest interface
    # to posting a new message.
    #
    def post(attributes)
      in_reply_to_message = attributes.delete(:in_reply_to_message)
      email = MList::EmailPost.new(attributes)
      process_message messages.build(
        :mail_list => self,
        :subscriber => attributes[:subscriber],
        :tmail => email.tmail
      )
    end
    
    # Processes the email received by the MList::Server which is destined for
    # the recipients of this list.
    #
    def process_email(email)
      process_message messages.build(
        :mail_list => self,
        :subscriber => list.subscriber(email.from_address),
        :tmail => email.tmail
      )
    end
    
    def been_there?(message)
      message.header_string('x-beenthere') == address
    end
    
    def list
      @list ||= manager_list
    end
    
    alias_method :ar_manager_list=, :manager_list=
    def manager_list=(list)
      if list.is_a?(ActiveRecord::Base)
        self.ar_manager_list = list
        @list = list
      else
        self.ar_manager_list = nil
        @list = list
      end
    end
    
    # TODO: Make private method (testing this should be done differently)
    def parent_identifier(message)
      if in_reply_to = message.header_string('in-reply-to')
        identifier = in_reply_to
      elsif references = message.read_header('references')
        identifier = references.ids.first
      else
        parent_message = messages.find(:first,
          :conditions => ['mlist_messages.subject = ?', remove_regard(message.subject)],
          :order => 'created_at asc'
        )
        identifier = parent_message.identifier if parent_message
      end
      remove_brackets(identifier) if identifier
    end
    
    def process?(message)
      !been_there?(message) && !recipients(message).blank?
    end
    
    def recipients(message)
      list.recipients(message.subscriber)
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
      
      def process_message(message)
        return unless process?(message)
        delivery_time = Time.now
        transaction do
          thread = assign_thread(message, delivery_time)
          update_attribute :updated_at, delivery_time
          prepare_delivery(message)
          outgoing_server.deliver(message.tmail)
        end
      end
      
      def prepare_delivery(message)
        prepare_list_headers(message)
        prepare_list_subject(message)
        message.to = address
        message.bcc = recipients(message)
        message.reply_to = "#{label} <#{post_url}>"
      end
      
      def prepare_list_headers(message)
        list_headers.each do |k,v|
          if TMail::Mail::ALLOW_MULTIPLE.include?(k.downcase)
            message.prepend_header(k,v)
          else
            message.write_header(k,v)
          end
        end
      end
      
      def prepare_list_subject(message)
        prefix = "[#{label}]"
        subject = message.subject.gsub(%r(#{Regexp.escape(prefix)}\s*), '')
        subject.gsub!(%r{(re:\s*){2,}}i, 'Re: ')
        message.subject = "#{prefix} #{subject}"
      end
      
      def assign_thread(message, delivery_time)
        message.parent_identifier = parent_identifier(message)
        message.parent = messages.find_by_identifier(message.parent_identifier)
        if message.parent
          thread = message.parent.thread
          thread.messages << message
          thread.update_attribute(:updated_at, delivery_time)
        else
          thread = threads.build
          thread.messages << message
          thread.save!
        end
        thread
      end
  end
end