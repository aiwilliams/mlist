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
      def deliver(tmail)
        @outgoing_server.deliver(tmail)
      end
      
      # Delegates fetching emails to incoming server.
      def execute
        @incoming_server.execute
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