require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'mlist/manager/database'

describe MList do
  def email_fixture(path)
    TMail::Mail.load(File.join(SPEC_ROOT, 'fixtures/email', path))
  end
  
  before :all do
    @listman = MList::Manager::Database.new
    @list = @listman.create_list('adam@thewilliams.ws')
    @list.subscribe('tom@example.com')
    @list.subscribe('dick@example.com')
    
    @email_server = MList::EmailServer::Fake.new
    @server = MList::Server.new(:listman => @listman, :email_server => @email_server)
    
    @email_server.receive(email_fixture('adam@thewilliams.ws'))
  end
  
  it 'should forward emails that are sent to a mailing list' do
    @email_server.deliveries.size.should == 1
    email = @email_server.deliveries.first
    email.should have_address(:to, 'adam@thewilliams.ws')
    email.should have_address(:bcc, %w(tom@example.com dick@example.com))
  end
  
  it 'should start a new thread for an email' do
    thread = MList::Thread.last
    thread.mails.first.tmail.should equal_tmail(@email_server.deliveries.first)
  end
end

# TODO Define behavior of multiple lists receiving an email