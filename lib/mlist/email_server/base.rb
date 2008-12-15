module MList
  module EmailServer
    class Base
      def initialize
        @receivers = []
      end
      
      def deliver(email)
        raise 'Implement actual delivery mechanism in subclasses'
      end
      
      def receive(email)
        mail = EmailServer::Email.new(email)
        @receivers.each { |r| r.receive(mail) }
      end
      
      def receiver(rx)
        @receivers << rx
      end
    end
  end
end
