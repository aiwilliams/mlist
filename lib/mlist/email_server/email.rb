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
      def addresses
        @tmail.to
      end
      
      def tmail
        @tmail.dup
      end
    end
  end
end