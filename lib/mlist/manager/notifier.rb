module MList
  module Manager
    
    # Constructs the notices that are sent to list subscribers. Applications
    # may subclass this to customize the content of a notice delivery.
    #
    class Notifier
      
      # Answers the delivery that will be sent to a subscriber when an
      # MList::List indicates that the distribution of an email from that
      # subscriber has been blocked.
      #
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