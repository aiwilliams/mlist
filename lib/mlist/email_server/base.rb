module MList
  module EmailServer
    class Base
      def initialize
        @receivers = []
      end
      
      def deliver(email)
        raise 'Implement actual delivery mechanism in subclasses'
      end
      
      def receive(tmail)
        email = MList::Email.new(:tmail => tmail)
        @receivers.each { |r| r.receive_email(email) }
      end
      
      def receiver(rx)
        @receivers << rx
      end
    end
  end
end
