require 'dispatcher' unless defined?(::Dispatcher)

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
Dispatcher.to_prepare(:activerecord_instantiate_observers) {
  ActiveRecord::Base.send(:subclasses).each(&:delete_observers)
  ActiveRecord::Base.instantiate_observers
}
