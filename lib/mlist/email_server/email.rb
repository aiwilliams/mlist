module MList
  module EmailServer
    
    # The interface to an incoming email.
    #
    # The primary goal is to decouple the MList::EmailServer from the
    # MList::Server, this class acting as the bridge.
    #
    class Email
      attr_reader :tmail
      
      def initialize(tmail)
        @tmail = tmail
      end
      
      def from_address
        @tmail.from.first.downcase
      end
      
      # Answers the usable destination addresses of the email.
      #
      def list_addresses
        bounce? ? @tmail.header_string('to').match(/\Amlist-(.*)\Z/)[1] : @tmail.to.collect(&:downcase)
      end
      
      # Answers true if this email is a bounce.
      #
      # TODO Delegate to the email_server's bounce detector.
      #
      def bounce?
        @tmail.header_string('to') =~ /mlist-/
      end
    end
  end
end