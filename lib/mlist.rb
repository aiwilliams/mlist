require 'tmail'
require 'activesupport'
require 'activerecord'

require 'mlist/util'
require 'mlist/message'
require 'mlist/list'
require 'mlist/mail_list'
require 'mlist/email_post'
require 'mlist/email_server'
require 'mlist/email_subscriber'
require 'mlist/server'
require 'mlist/thread'

module MList
end

Time::DATE_FORMATS[:mlist_reply_timestamp] = Date::DATE_FORMATS[:mlist_reply_timestamp] = '%a, %b %e, %Y at %l:%M %p'
TMail::Mail::ALLOW_MULTIPLE['x-beenthere'] = true