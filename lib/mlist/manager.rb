require 'mlist/manager/notifier'

module MList
  
  # The interface of list managers.
  #
  # A module is provided instead of a base class to allow implementors to
  # subclass whatever they like. Practically speaking, they can create an
  # ActiveRecord subclass.
  #
  module Manager
    
    # Answers an enumeration of MList::List implementations to which the given
    # email should be published.
    #
    def lists(email)
      raise 'implement in your list manager'
    end
    
    # Answers the MList::Manager::Notifier of this list manager. Includers of
    # this module may initialize the @notifier instance variable with their
    # own implementation/subclass to generate custom content for the different
    # notices.
    #
    def notifier
      @notifier ||= MList::Manager::Notifier.new
    end
  end
  
end