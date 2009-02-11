module MList
  module Manager
    
    class Notifier
      def subscriber_blocked(list, email, subscriber)
        delivery = MList::Util::TMailBuilder.new(TMail::Mail.new)
        delivery.write_header('x-mlist-loop', 'notice')
        delivery.write_header('x-mlist-notice', 'subscriber_blocked')
        delivery.to = subscriber.email_address
        delivery.from = "mlist-#{list.address}"
        prepare_subscriber_blocked_content(list, email, subscriber, delivery)
        delivery
      end
      
      protected
        def prepare_subscriber_blocked_content(list, email, subscriber, delivery)
          delivery.set_content_type('text/plain')
          delivery.body = %{Although you are a subscriber to this list, your message cannot be posted at this time. Please contact the administrator of the list.}
        end
    end
    
  end
end