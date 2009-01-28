module MList
  class MailList < ActiveRecord::Base
    set_table_name 'mlist_mail_lists'
    
    def self.find_or_create_by_list(list)
      if list.is_a?(ActiveRecord::Base)
        find_or_create_by_manager_list_identifier_and_manager_list_type_and_manager_list_id(
          list.list_id, list.class.base_class.name, list.id
        )
      else
        mail_list = find_or_create_by_manager_list_identifier(list.list_id)
        mail_list.manager_list = list
        mail_list
      end
    end
    
    belongs_to :manager_list, :polymorphic => true
    
    has_many :messages, :class_name => 'MList::Message', :dependent => :delete_all
    has_many :threads, :class_name => 'MList::Thread', :dependent => :delete_all
    
    delegate :address, :label, :post_url, :subscribers,
             :to => :list
    
    def post(email_server, email)
      message = messages.build(
        :subscriber => list.subscriber(email.from_address),
        :tmail => email.tmail
      )
      
      return unless process?(message)
      prepare_delivery(message)
      deliver(message, email_server)
    end
    
    def been_there?(message)
      message.header_string('x-beenthere') == address
    end
    
    # http://mail.python.org/pipermail/mailman-developers/2006-April/018718.html
    def bounce_headers
      {'sender'    => "mlist-#{address}",
       'errors-to' => "mlist-#{address}"}
    end
    
    def deliver(message, email_server)
      deliver_time = Time.now
      transaction do
        email_server.deliver(message.tmail)
        thread = find_thread(message)
        thread.messages << message
        thread.new_record? ? thread.save! : thread.update_attribute(:updated_at, deliver_time)
        update_attribute :updated_at, deliver_time
      end
    end
    
    def find_thread(message)
      if message.reply?
        threads.find(:first,
          :joins => :messages,
          :readonly => false,
          :conditions => ['mlist_messages.identifier = ?', message.parent_identifier]
        )
      else
        threads.build
      end
    end
    
    def list
      @list ||= manager_list
    end
    
    # http://www.jamesshuggins.com/h/web1/list-email-headers.htm
    def list_headers
      headers = list.list_headers
      headers['x-beenthere'] = address
      headers.update(bounce_headers)
      headers.delete_if {|k,v| v.nil?}
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
    
    def prepare_delivery(message)
      prepare_list_headers(message)
      message.to = address
      message.bcc = recipients(message)
      message.reply_to = "#{label} <#{post_url}>"
    end
    
    def prepare_list_headers(message)
      list_headers.each do |k,v|
        message.write_header(k,v)
      end
    end
    
    def process?(message)
      !been_there?(message) && !recipients(message).blank?
    end
    
    def recipients(message)
      list.recipients(message.subscriber)
    end
  end
end