module MList
  module EmailServer
    
    class Default < Base
      def initialize(incoming_server, outgoing_server)
        super({})
        @incoming_server, @outgoing_server = incoming_server, outgoing_server
        @incoming_server.receiver(self)
      end
      
      # Delegates delivery of email to outgoing server.
      #
      def deliver(tmail, destinations)
        @outgoing_server.deliver(tmail, destinations)
      end
      
      # Delegates processing of email from incoming server to receivers on
      # self.
      #
      def receive_email(email)
        @receivers.each { |r| r.receive_email(email) }
      end
    end
    
  end
end