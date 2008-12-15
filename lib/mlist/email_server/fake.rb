module MList
  module EmailServer
    class Fake < Base
      attr_reader :deliveries
      
      def initialize
        super
        @deliveries = []
      end
      
      def deliver(email)
        @deliveries << email
      end
    end
  end
end
