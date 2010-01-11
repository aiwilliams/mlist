module MList
  class Server
    attr_reader :list_manager, :email_server, :notifier
    
    def initialize(config)
      @list_manager = config[:list_manager]
      @email_server = config[:email_server]
      @notifier = MList::Manager::Notifier.new
      @email_server.receiver(self)
    end
    
    def receive_email(email)
      lists = list_manager.lists(email)
      if lists.empty?
        list_manager.no_lists_found(email)
      elsif email.bounce?
        process_bounce(lists.first, email)
      else
        process_post(lists, email)
      end
    end
    
    def mail_list(list)
      MailList.find_or_create_by_list(list, @email_server)
    end
    
    protected
      def process_post(lists, email)
        lists.each do |list|
          next if list.been_here?(email)
          if list.subscriber?(email.from_address)
            publish_if_list_active(list, email)
          else
            list.non_subscriber_post(email)
          end
        end
      end
      
      def publish_if_list_active(list, email)
        if list.active?
          subscriber = list.subscriber(email.from_address)
          publish_unless_blocked(list, email, subscriber)
        else
          list.inactive_post(email)
        end
      end
      
      def publish_unless_blocked(list, email, subscriber)
        if list.blocked?(subscriber)
          notice_delivery = notifier.subscriber_blocked(list, email, subscriber)
          email_server.deliver(notice_delivery.tmail)
        else
          mail_list(list).process_email(email, subscriber)
        end
      end
      
      def process_bounce(list, email)
        list.bounce(email)
      end
      
  end
end