require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'mlist/manager/database'

describe MList do
  def email_fixture(path)
    TMail::Mail.load(File.join(SPEC_ROOT, 'fixtures/email', path))
  end
  
  dataset {}
  
  before do
    @listman = MList::Manager::Database.new
    @email_server = MList::EmailServer::Fake.new
    @server = MList::Server.new(
      :listman => @listman,
      :email_server => @email_server
    )
    
    # TODO Move this stuff to Dataset
    ActiveRecord::Base.connection.increment_open_transactions
    ActiveRecord::Base.connection.begin_db_transaction
  end
  
  after do
    if ActiveRecord::Base.connection.open_transactions != 0
      ActiveRecord::Base.connection.rollback_db_transaction
      ActiveRecord::Base.connection.decrement_open_transactions
    end
    ActiveRecord::Base.clear_active_connections!
  end
  
  describe 'single list' do
    before do
      @list = @listman.create_list('adam@thewilliams.ws')
      @list.subscribe('tom@example.com')
      @list.subscribe('dick@example.com')
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
  
  describe 'multiple lists' do
    before do
      @list = @listman.create_list('adam@thewilliams.ws')
      @list.subscribe('tom@example.com')
      @list = @listman.create_list('nospam@thewilliams.ws')
      @list.subscribe('dick@example.com')
      @email_server.receive(email_fixture('multiple_lists'))
    end
    
    it 'should forward emails that are sent to a mailing list' do
      @email_server.deliveries.size.should == 2
      email = @email_server.deliveries.first
      email.should have_address(:to, 'adam@thewilliams.ws')
      email.should have_address(:bcc, %w(tom@example.com))
      email = @email_server.deliveries.last
      email.should have_address(:to, 'nospam@thewilliams.ws')
      email.should have_address(:bcc, %w(dick@example.com))
    end
    
    it 'should start a new thread for each list' do
      threads = MList::Thread.find(:all)
      threads[0].mails.first.tmail.should equal_tmail(@email_server.deliveries[0])
      threads[1].mails.first.tmail.should equal_tmail(@email_server.deliveries[1])
    end
  end
end

# TODO Define behavior of multiple lists receiving an email