module MList
  module List
    def deliver(email_server, mail)
      mail.to = address
      mail.bcc = subscriptions.collect(&:address)
      email_server.deliver(mail.tmail)
      thread = Thread.new
      thread.mails << mail
      thread.save!
    end
  end
end