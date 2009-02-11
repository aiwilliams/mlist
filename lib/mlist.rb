require 'uuid'
require 'tmail'
require 'activesupport'
require 'activerecord'

require 'mlist/util'
require 'mlist/email'
require 'mlist/message'
require 'mlist/list'
require 'mlist/mail_list'
require 'mlist/email_post'
require 'mlist/email_server'
require 'mlist/email_subscriber'
require 'mlist/server'
require 'mlist/thread'

require 'mlist/manager'

module MList
  class DoubleDeliveryError < StandardError
    def initialize(message)
      super("A message should never be delivered more than once. An attempt was made to deliver this message:\n#{message.inspect}")
    end
  end
end

Time::DATE_FORMATS[:mlist_reply_timestamp] = Date::DATE_FORMATS[:mlist_reply_timestamp] = lambda do |time|
  time.strftime('%a, %b %d, %Y at %I:%M %p').sub(/0(\d,)/, '\1').sub(/0(\d:)/, '\1')
end

# In order to keep the inline images in email intact. Certainly a scary bit of
# hacking, but this is the solution out there on the internet.
TMail::HeaderField::FNAME_TO_CLASS.delete 'content-id'

TMail::Mail::ALLOW_MULTIPLE['x-beenthere'] = true