module MList
  module EmailServer
    class Fake < Base
      attr_reader :deliveries
      
      def initialize(settings = {})
        super
        @deliveries = []
      end
      
      def deliver(tmail)
        @deliveries << tmail
      end
    end
  end
end
