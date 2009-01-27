require 'pop_ssl'

module MList
  module EmailServer
    class Pop < Base
      attr_reader :configuration
      
      def initialize(configuration)
        super()
        
        @configuration = configuration
      end
      
      def deliver(email)
        raise "Mail cannot be delivered through a POP server. Please use the '#{MList::EmailServer::Default.name}' type."
      end
      
      def execute
        connect_to_email_account do |pop|
          pop.mails.each { |message| receive(TMail::Mail.parse(message.pop)); message.delete }
        end
      end
      
      private
        def connect_to_email_account
          pop3 = Net::POP3.new(configuration[:server], configuration[:port], false)
          pop3.enable_ssl if configuration[:ssl]
          pop3.start(configuration[:username], configuration[:password]) do |pop|
            yield pop
          end
        end
    end
  end
end