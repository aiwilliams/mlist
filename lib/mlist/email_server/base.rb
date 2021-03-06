module MList
  module EmailServer
    class Base
      attr_reader :settings
      
      def initialize(settings)
        @settings = {
          :domain => ::Socket.gethostname
        }.merge(settings)
        
        @uuid = UUID.new
        @receivers = []
      end
      
      def deliver(tmail)
        raise 'Implement actual delivery mechanism in subclasses'
      end
      
      def generate_message_id
        "#{@uuid.generate}@#{@settings[:domain]}"
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
