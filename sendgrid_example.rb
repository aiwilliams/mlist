$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'mlist'
require 'mlist/email_server/smtp'
require 'singleton'

require 'active_record'
SQLITE_DATABASE = "spec/sqlite3.db"
ActiveRecord::Base.silence do
  ActiveRecord::Base.configurations = {'test' => {
    'adapter' => 'sqlite3',
    'database' => SQLITE_DATABASE
  }}
  ActiveRecord::Base.establish_connection 'test'
  load "spec/fixtures/schema.rb"
end


class MailList
  include Singleton
  include MList::List
  
  def address
    'sendgridtest@discuss.memberhub.com'
  end
  
  def label
    'Sendgrid Testing'
  end
  
  def list_id
    "sendgrid_testing"
  end
  
  def subscribers
    [MList::EmailSubscriber.new('something@nomail.net'), MList::EmailSubscriber.new('anotherthing@nomail.net')]
  end
end

class ListManager
  include MList::Manager
  
  def lists(email)
    [MailList.instance]
  end
end

list_manager = ListManager.new
mlist_server = MList::Server.new(
  :list_manager => list_manager,
  :email_server => MList::EmailServer::Smtp.new(
    :enable_starttls_auto => true,
    :address => "smtp.sendgrid.net",
    :port => "587",
    :authentication => :plain,
    :domain => 'your.domain.com',
    :user_name => "smtp@your.domain.com",
    :password => "yourpassword"
  )
)

post = MList::EmailPost.new({
  :subscriber => MailList.instance.subscribers.first,
  :subject => "I'm a Program!",
  :text => "My simple message that isn't too short"
})

mlist_server.mail_list(MailList.instance).post(post)