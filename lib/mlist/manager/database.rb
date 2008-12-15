module MList
  module Manager
    
    class Database < Base
      def create_list(address)
        List.create!(:address => address)
      end
      
      def lists(email)
        lists = List.find_all_by_address(email.addresses)
        email.addresses.map { |a| lists.detect {|l| l.address == a} }
      end
      
      class List < ActiveRecord::Base
        include ::MList::List
        
        has_many :subscriptions, :dependent => :delete_all
        
        def subscribe(address)
          subscriptions.find_or_create_by_address(address)
        end
      end
      
      class Subscription < ActiveRecord::Base
        belongs_to :list
      end
    end
    
  end
end