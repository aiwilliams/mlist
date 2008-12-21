module MList
  class Server
    attr_reader :list_manager, :email_server
    
    def initialize(config)
      @list_manager = config[:list_manager]
      @email_server = config[:email_server]
      @email_server.receiver(self)
    end
    
    def receive(email)
      lists = list_manager.lists(email)
      if email.bounce?
        process_bounce(lists.first, email)
      else
        process_post(lists, email)
      end
    end
    
    protected
      def process_bounce(list, email)
        list.bounce(email)
      end
      
      def process_post(lists, email)
        lists.each do |list|
          if list.subscriber?(email.from_address)
            mail_list = MailList.find_or_create_by_list(list)
            mail_list.post(email_server, MList::Mail.new(:mail_list => mail_list, :tmail => email.tmail))
          else
            list.non_subscriber_posted(email)
          end
        end
      end
  end
end