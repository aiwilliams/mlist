# Provides the mechinism to support applications that want to observe MList
# models.
#
# ActiveRecord observers are reloaded at each request in development mode.
# They will be registered with the MList models each time. Since the MList
# models are required once at initialization, there will always only be one
# instance of the model class, and therefore, many instances of the observer
# class registered with it; all but the most recent are invalid, since they
# were undefined when the dispatcher reloaded the application.
#
# Should we ever have observers in MList, this will likely need more careful
# attention.
#
unless Rails.configuration.cache_classes
  class << ActiveRecord::Base
    def instantiate_observers_with_mlist_observers
      subclasses.each(&:delete_observers)
      instantiate_observers_without_mlist_observers
    end
    alias_method_chain :instantiate_observers, :mlist_observers
  end
end