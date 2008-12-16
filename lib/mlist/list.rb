module MList
  module List
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
      
      def prepare_delivery(mail)
        mail.write_header('X-BeenThere', address)
        mail.to = address
        mail.bcc = subscriptions.collect(&:address)
      end
      
      def process?(mail)
        !beenthere?(mail)
      end
  end
end