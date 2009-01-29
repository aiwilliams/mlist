require 'tmail'
require 'activerecord'

require 'mlist/util'
require 'mlist/message'
require 'mlist/list'
require 'mlist/mail_list'
require 'mlist/email_server'
require 'mlist/email_subscriber'
require 'mlist/server'
require 'mlist/thread'

module MList
end

TMail::Mail::ALLOW_MULTIPLE['x-beenthere'] = true