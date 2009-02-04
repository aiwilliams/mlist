module MList
  module EmailServer
    class Base
      attr_reader :settings
      
      def initialize(settings)
        @settings = settings
        @receivers = []
      end
      
      def deliver(tmail, destinations)
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
