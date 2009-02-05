module MList
  module Manager
    
    class Database
      def create_list(address, attributes = {})
        attributes = {
          :address => address,
          :label   => address.match(/\A(.*?)@/)[1]
        }.merge(attributes)
        List.create!(attributes)
      end
      
      def lists(email)
        lists = List.find_all_by_address(email.list_addresses)
        email.list_addresses.map { |a| lists.detect {|l| l.address == a} }.compact
      end
      
      def no_lists_found(email)
        # your application may care
      end
      
      class List < ActiveRecord::Base
        include ::MList::List
        
        has_many :subscribers, :dependent => :delete_all
        
        def list_id
          "#{self.class.name}#{id}"
        end
        
        def subscribe(address)
          subscribers.find_or_create_by_email_address(address)
        end
      end
      
      class Subscriber < ActiveRecord::Base
        belongs_to :list
      end
    end
    
  end
end