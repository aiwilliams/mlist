module MList
  module Manager

    class Database
      include ::MList::Manager

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
        # TODO: Move to notifier
      end

      class List < ActiveRecord::Base
        include ::MList::List

        has_many :subscribers, :dependent => :delete_all

        def label
          self[:label]
        end

        def list_id
          "#{self.class.name}#{id}"
        end

        def subscribe(address)
          subscribers.find_or_create_by_rfc5322_email(address)
        end
      end

      class Subscriber < ActiveRecord::Base
        belongs_to :list
      end
    end

  end
end
