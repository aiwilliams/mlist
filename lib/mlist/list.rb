module MList
  
  # Represents the interface of the lists that a list manager must answer.
  # This is distinct from the MList::MailList to allow for greater flexibility
  # in processing email coming to a list - that is, whatever you include this
  # into may re-define behavior appropriately.
  #
  module List
    
    # Answers whether this list is active or not.
    #
    def active?
      true
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
    
    def recipients(message)
      subscriptions.collect(&:address) - [message.from_address]
    end
    
    def subscriber?(address)
      !subscriptions.detect {|s| s.address == address}.nil?
    end
    
    # Methods that will be invoked on your implementation of Mlist::List when
    # certain events occur during the processing of email sent to a list.
    #
    module Callbacks
      def bounce(email)
      end
      
      # Called when an email is a post to the list while the list is inactive
      # (answers false to _active?_). This will not be called if the email is
      # from a non-subscribed sender. Instead, _non_subscriber_post_ will be
      # called.
      #
      def inactive_post(email)
      end
      
      # Called when an email is a post to the list from a non-subscribed
      # sender. This will be called even if the list is inactive.
      #
      def non_subscriber_post(email)
      end
    end
    include Callbacks
    
  end
end