require 'net/smtp'

module MList
  module EmailServer
    
    class Smtp < Base
      def deliver(tmail)
        destinations = tmail.destinations
        tmail.delete_no_send_fields
        smtp = Net::SMTP.new(settings[:address], settings[:port])
        smtp.enable_starttls_auto if settings[:enable_starttls_auto] && smtp.respond_to?(:enable_starttls_auto)
        smtp.start(settings[:domain], settings[:user_name], settings[:password],
                   settings[:authentication]) do |smtp|
          smtp.sendmail(tmail.encoded, tmail['sender'], destinations)
        end
      end
      
      def execute
        raise "Mail cannot be received through an SMTP server. Please use the '#{MList::EmailServer::Default.name}' type."
      end
    end
    
  end
end