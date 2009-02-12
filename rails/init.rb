require 'dispatcher' unless defined?(::Dispatcher)

Dispatcher.module_eval do
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
  # Why not an initializer "to_prepare" block? Simply because we must clear
  # the observers in the ActiveRecord classes before the
  # ActiveRecord::Base.instantiate_observers call is made by the prepare block
  # that we cannot get in front of with the initializer approach. Also, it
  # lessens the configuration burden of the MList client application.
  #
  # Should we ever have observers in MList, this will likely need more careful
  # attention.
  #    
  def reload_application_with_plugin_record_support
    ActiveRecord::Base.send(:subclasses).each(&:delete_observers)
    reload_application_without_plugin_record_support
  end
  alias_method_chain :reload_application, :plugin_record_support
end