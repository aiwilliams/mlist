require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'mlist/manager/database'

describe MList do
  def email_fixture(path)
    TMail::Mail.load(File.join(SPEC_ROOT, 'fixtures/email', path))
  end
  
  dataset do
    @listman = MList::Manager::Database.new
    @list_one = @listman.create_list('list_one@example.com')
    @list_one.subscribe('tom@example.com')
    @list_one.subscribe('dick@example.com')
    
    @list_two = @listman.create_list('list_two@example.com')
    @list_two.subscribe('jane@example.com')
  end
  
  before do
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
      @email_server.receive(email_fixture('single_list'))
    end
    
    it 'should forward emails that are sent to a mailing list' do
      @email_server.deliveries.size.should == 1
      email = @email_server.deliveries.first
      email.should have_address(:to, 'list_one@example.com')
      email.should have_address(:bcc, %w(tom@example.com dick@example.com))
    end
    
    it 'should start a new thread for an email' do
      thread = MList::Thread.last
      thread.mails.first.tmail.should equal_tmail(@email_server.deliveries.first)
    end
  end
  
  describe 'multiple lists' do
    before do
      @email_server.receive(email_fixture('multiple_lists'))
    end
    
    it 'should forward emails that are sent to a mailing list' do
      @email_server.deliveries.size.should == 2
      
      email = @email_server.deliveries.first
      email.should have_address(:to, 'list_one@example.com')
      email.should have_address(:bcc, %w(tom@example.com dick@example.com))
      
      email = @email_server.deliveries.last
      email.should have_address(:to, 'list_two@example.com')
      email.should have_address(:bcc, %w(jane@example.com))
    end
    
    it 'should start a new thread for each list' do
      threads = MList::Thread.find(:all)
      threads[0].mails.first.tmail.should equal_tmail(@email_server.deliveries[0])
      threads[1].mails.first.tmail.should equal_tmail(@email_server.deliveries[1])
    end
  end
  
  describe 'x-beenthere' do
    it 'should not be received by the list' do
      lambda do
        @email_server.receive(email_fixture('x-beenthere'))
        @email_server.deliveries.size.should == 0
      end.should_not change(MList::Thread, :count)
    end
  end
end