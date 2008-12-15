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
      lists.each { |list| list.deliver(email_server, MList::Mail.new(:tmail => mail.tmail)) }
    end
  end
end