module MList
  
  # Represents the interface of the lists that a list manager must answer.
  # This is distinct from the MList::MailList to allow for greater flexibility
  # in processing email coming to a list - that is, whatever you include this
  # into may re-define behavior appropriately.
  #
  module List
    
    # Answers whether this list is active or not. All lists are active all the
    # time by default.
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
      raise 'answer a unique, never changing value'
    end
    
    def name
      address.match(/\A(.*?)@/)[1]
    end
    
    def post_url
      address
    end
    
    # A list is responsible for answering the recipient subscribers.
    
    # The subscriber of the incoming message is provided if the list would
    # like to exclude it from the returned list. It is not assumed that it
    # will be included or excluded, thereby allowing the list to decide. This
    # default implementation does not include the sending subscriber in the
    # list of recipients.
    #
    # Your 'subscriber' instance MUST respond to :email_address. They may
    # optionally respond to :display_name.
    #
    def recipients(subscriber)
      subscribers.reject {|s| s.email_address == subscriber.email_address}
    end
    
    def subscriber(email_address)
      subscribers.detect {|s| s.email_address == email_address}
    end
    
    def subscriber?(email_address)
      !subscriber(email_address).nil?
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