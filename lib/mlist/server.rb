module MList
  class Server
    attr_reader :list_manager, :email_server
    
    def initialize(config)
      @list_manager = config[:list_manager]
      @email_server = config[:email_server]
      @email_server.receiver(self)
    end
    
    def receive(mail)
      lists = list_manager.lists(mail)
      lists.each do |list|
        mail_list = MailList.find_or_create_by_list(list)
        mail_list.post(email_server, MList::Mail.new(:mail_list => mail_list, :tmail => mail.tmail))
      end
    end
  end
end