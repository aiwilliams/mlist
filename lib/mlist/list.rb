module MList
  
  # Represents the interface of the lists that a list manager must answer.
  # This is distinct from the MList::MailList to allow for greater flexibility
  # in processing email coming to a list - that is, whatever you include this
  # into may re-define behavior appropriately.
  #
  # Your 'subscriber' instances MUST respond to :email_address. They may
  # optionally respond to :display_name.
  #
  module List
    
    # Answers whether this list is active or not. All lists are active all the
    # time by default.
    #
    def active?
      true
    end
    
    # Answers whether the subscriber is blocked from posting or not. This will
    # not be asked when the list is not active (answers _active?_ as false).
    #
    def blocked?(subscriber)
      false
    end
    
    # Answers the footer content for this list. Default implementation is very
    # simple.
    #
    def footer_content(message)
      %Q{The "#{label}" mailing list\nPost messages: #{post_url}}
    end
    
    # Answer a suitable label for the list, which will be used in various
    # parts of content that is delivered to subscribers, etc.
    #
    def label
      raise 'answer the list label'
    end
    
    # Answers the headers that are to be included in the emails delivered for
    # this list. Any entries that have a nil value will not be included in the
    # delivered email.
    #
    def list_headers
      {
        'list-id'          => list_id,
        'list-archive'     => archive_url,
        'list-subscribe'   => subscribe_url,
        'list-unsubscribe' => unsubscribe_url,
        'list-owner'       => owner_url,
        'list-help'        => help_url,
        'list-post'        => post_url
      }
    end
    
    # Answers a unique, never changing value for this list.
    #
    def list_id
      raise 'answer a unique, never changing value'
    end
    
    # The web address where an archive of this list may be found, nil if there
    # is no archive.
    #
    def archive_url
      nil
    end
    
    # The web address of the list help site, nil if this is not supported.
    #
    def help_url
      nil
    end
    
    # The email address of the list owner, nil if this is not supported.
    #
    def owner_url
      nil
    end
    
    # The email address where posts should be sent. Defaults to the address of
    # the list.
    #
    def post_url
      address
    end
    
    # Should the reply-to header be set to the list's address? Defaults to
    # true. If false is returned, the reply-to will be the subscriber address.
    #
    def reply_to_list?
      true
    end
    
    # The web url where subscriptions to this list may be created, nil if this
    # is not supported.
    #
    def subscribe_url
      nil
    end
    
    # The web url where subscriptions to this list may be deleted, nil if this
    # is not supported.
    #
    def unsubscribe_url
      nil
    end
    
    # A list is responsible for answering the recipient subscribers.
    #
    # The subscriber of the incoming message is provided if the list would
    # like to exclude it from the returned list. It is not assumed that it
    # will be included or excluded, thereby allowing the list to decide. This
    # default implementation does not include the sending subscriber in the
    # list of recipients.
    #
    def recipients(subscriber)
      subscribers.reject {|s| s.email_address == subscriber.email_address}
    end
    
    # A list must answer the subscriber who's email address is that of the one
    # provided. The default implementation will pick the first instance that
    # answers subscriber.email_address == email_address. Your implementation
    # should probably select just one record.
    #
    def subscriber(email_address)
      subscribers.detect {|s| s.email_address == email_address}
    end
    
    # A list must answer whether there is a subscriber who's email address is
    # that of the one provided. This is checked before the subscriber is
    # requested in order to allow for the lightest weight check possible; that
    # is, your implementation could avoid loading the actual subscriber
    # instance.
    #
    def subscriber?(email_address)
      !subscriber(email_address).nil?
    end
    
    # Methods that will be invoked on your implementation of Mlist::List when
    # certain events occur during the processing of email sent to a list.
    #
    module Callbacks
      
      # Called when an email is a post to the list by a subscriber whom the
      # list claims is blocked (answers true to _blocked?(subscriber)_). This
      # will not be called if the list is inactive (answers false to
      # _active?_);
      #
      def blocked_subscriber_post(email, subscriber)
      end
      
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