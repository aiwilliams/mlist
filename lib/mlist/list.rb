module MList
  
  # Represents the interface of the lists that a list manager must answer.
  # This is distinct from the MList::MailList to allow for greater flexibility
  # in processing mail coming to a list - that is, whatever you include this
  # into may re-define behavior appropriately.
  #
  module List
    def bounce(email)
      
    end
    
    def host
      address.match(/@(.*)\Z/)[1]
    end
    
    def list_headers
      {
        'list-id'          => list_id,
        'list-archive'     => (archive_url rescue nil),
        'list-subscribe'   => (subscribe_url rescue nil),
        'list-unsubscribe' => (unsubscribe_url rescue nil),
        'list-owner'       => (owner_url rescue nil),
        'list-help'        => (help_url rescue nil),
        'list-post'        => post_url
      }
    end
    
    def list_id
      "#{label} <#{address}>"
    end
    
    def name
      address.match(/\A(.*?)@/)[1]
    end
    
    def post_url
      address
    end
    
    def recipients(mail)
      subscriptions.collect(&:address) - [mail.from_address]
    end
    
    def subscriber?(address)
      !subscriptions.detect {|s| s.address == address}.nil?
    end
  end
end