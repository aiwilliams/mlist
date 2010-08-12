module MList

  # Represents a simple subscriber instance, wrapping an email address.
  #
  EmailSubscriber = Struct.new('EmailSubscriber', :rfc5322_email)
end
