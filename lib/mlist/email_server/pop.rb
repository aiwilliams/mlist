require 'pop_ssl'

module MList
  module EmailServer
    
    class Pop < Base
      def deliver(tmail, destinations)
        raise "Mail cannot be delivered through a POP server. Please use the '#{MList::EmailServer::Default.name}' type."
      end
      
      def execute
        connect_to_email_account do |pop|
          pop.mails.each { |message| receive(TMail::Mail.parse(message.pop)); message.delete }
        end
      end
      
      private
        def connect_to_email_account
          pop3 = Net::POP3.new(settings[:server], settings[:port], false)
          pop3.enable_ssl if settings[:ssl]
          pop3.start(settings[:username], settings[:password]) do |pop|
            yield pop
          end
        end
    end
    
  end
end