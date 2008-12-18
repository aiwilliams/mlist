module MList
  class MailList < ActiveRecord::Base
    def self.find_or_create_by_list(list)
      mail_list = find_or_create_by_identifier(list.list_id)
      mail_list.manager_list = list
      mail_list
    end
    
    has_many :mails, :dependent => :delete_all
    has_many :threads, :dependent => :delete_all
    
    attr_accessor :manager_list
    delegate :list_id, :address, :host, :label,
             :name, :post_url, :subscriptions,
             :archive_url, :subscribe_url, :unsubscribe_url,
             :owner_url, :help_url,
             :to => :manager_list
    
    def post(email_server, mail)
      return unless process?(mail)
      prepare_delivery(mail)
      deliver(mail, email_server)
    end
    
    def been_there?(mail)
      mail.header_string('x-beenthere') == address
    end
    
    def deliver(mail, email_server)
      transaction do
        email_server.deliver(mail.tmail)
        thread = find_thread(mail)
        thread.mails << mail
        thread.save!
      end
    end
    
    def find_thread(mail)
      if mail.reply?
        threads.find(:first,
          :joins => :mails,
          :readonly => false,
          :conditions => ['mails.identifier = ?', mail.parent_identifier]
        )
      else
        threads.build
      end
    end
    
    # http://www.jamesshuggins.com/h/web1/list-email-headers.htm
    def list_headers
      headers = {
        'list-id'          => list_id,
        'list-archive'     => (archive_url rescue nil),
        'list-subscribe'   => (subscribe_url rescue nil),
        'list-unsubscribe' => (unsubscribe_url rescue nil),
        'list-owner'       => (owner_url rescue nil),
        'list-help'        => (help_url rescue nil),
        'list-post'        => post_url,
        'x-beenthere'      => address
      }
      headers.delete_if {|k,v| v.nil?}
      headers
    end
    
    def prepare_delivery(mail)
      prepare_list_headers(mail)
      mail.to = address
      mail.bcc = subscriptions.collect(&:address)
    end
    
    def prepare_list_headers(mail)
      list_headers.each do |k,v|
        mail.write_header(k,v)
      end
    end
    
    def process?(mail)
      !been_there?(mail)
    end
  end
end