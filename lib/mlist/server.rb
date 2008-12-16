module MList
  class Server
    attr_reader :listman, :email_server
    
    def initialize(config)
      @listman = config[:listman]
      @email_server = config[:email_server]
      @email_server.receiver(self)
    end
    
    def receive(mail)
      lists = listman.lists(mail)
      lists.each do |list|
        list_mail = MList::Mail.new(:tmail => mail.tmail)
        list.receive(email_server, list_mail)
      end
    end
  end
end