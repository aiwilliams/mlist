module MList
  module List
    def host
      address.match(/@(.*)\Z/)[1]
    end
    
    def list_id
      "#{label} <#{address}>"
    end
    
    def name
      address.match(/\A(.*?)@/)[1]
    end
    
    def post_url
      address
    end
    
    def receive(email_server, mail)
      return unless process?(mail)
      prepare_delivery(mail)
      deliver(mail, email_server)
    end
    
    private
      def beenthere?(mail)
        mail.header_string('x-beenthere') == address
      end
      
      def deliver(mail, email_server)
        Thread.transaction do
          email_server.deliver(mail.tmail)
          thread = Thread.new
          thread.mails << mail
          thread.save!
        end
      end
      
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
        !beenthere?(mail)
      end
  end
end