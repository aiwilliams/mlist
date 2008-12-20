module MList
  module EmailServer
    
    # The interface to an incoming email, providing assurance that the
    # MList::Server and it's sub-systems don't stomp all over each other by
    # getting a reference to a single TMail::Mail instance.
    #
    class Email
      def initialize(tmail)
        @tmail = tmail
      end
      
      # Answers the usable destination addresses of the email.
      #
      # TODO: Provide intelligence to this that allows it to ignore addresses
      # that are not for the server domain.
      #
      def list_addresses
        bounce? ? @tmail.header_string('to').match(/\Amlist-(.*)\Z/)[1] : @tmail.to
      end
      
      def bounce?
        @tmail.header_string('to') =~ /mlist-/
      end
      
      def tmail
        TMail::Mail.parse(@tmail.to_s)
      end
    end
  end
end