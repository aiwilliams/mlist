module MList
  class MailList < ActiveRecord::Base
    def self.find_or_create_by_list(list)
      mail_list = find_or_create_by_identifier(list.list_id)
      mail_list.manager_list = list
      mail_list
    end
    
    has_many :messages, :dependent => :delete_all
    has_many :threads, :dependent => :delete_all
    
    attr_accessor :manager_list
    delegate :address, :recipients, :subscriptions,
             :to => :manager_list
    
    def post(email_server, message)
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
      transaction do
        email_server.deliver(message.tmail)
        thread = find_thread(message)
        thread.messages << message
        thread.save!
      end
    end
    
    def find_thread(message)
      if message.reply?
        threads.find(:first,
          :joins => :messages,
          :readonly => false,
          :conditions => ['messages.identifier = ?', message.parent_identifier]
        )
      else
        threads.build
      end
    end
    
    # http://www.jamesshuggins.com/h/web1/list-email-headers.htm
    def list_headers
      headers = manager_list.list_headers
      headers['x-beenthere'] = address
      headers.update(bounce_headers)
      headers.delete_if {|k,v| v.nil?}
    end
    
    def prepare_delivery(message)
      prepare_list_headers(message)
      message.to = address
      message.bcc = recipients(message)
    end
    
    def prepare_list_headers(message)
      list_headers.each do |k,v|
        message.write_header(k,v)
      end
    end
    
    def process?(message)
      !been_there?(message) && !recipients(message).blank?
    end
  end
end