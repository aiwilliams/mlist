require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'mlist/manager/database'

describe MList do
  dataset do
    @list_manager = MList::Manager::Database.new
    @list_one = @list_manager.create_list('list_one@example.com')
    @list_one.subscribe('tom@example.com')
    @list_one.subscribe('dick@example.com')
    
    @list_two = @list_manager.create_list('list_two@example.com')
    @list_two.subscribe('jane@example.com')
    
    @empty_list = @list_manager.create_list('empty@example.com')
  end
  
  before do
    @email_server = MList::EmailServer::Fake.new
    @server = MList::Server.new(
      :list_manager => @list_manager,
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
  
  it 'should not forward mail when there are no subscriptions' do
    email = email_fixture('single_list')
    email.to = @empty_list.address
    @email_server.receive(email)
    @email_server.deliveries.should be_empty
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
    
    it 'should start a new thread for a new email' do
      thread = MList::Thread.last
      thread.mails.first.tmail.should equal_tmail(@email_server.deliveries.first)
    end
    
    it 'should add to an existing thread when reply email' do
      @email_server.receive(email_fixture('single_list_reply'))
      thread = MList::Thread.last
      thread.mails.size.should be(2)
      thread.mails.last.tmail.should equal_tmail(@email_server.deliveries.last)
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
  
  describe 'bounces' do
    it 'should be reported to the list manager without saving it' do
      stub(@list_manager).lists(is_a(MList::EmailServer::Email)) { [@list_one] }
      mock(@list_one).bounce(is_a(MList::EmailServer::Email))
      lambda do
        @email_server.receive(email_fixture('bounces/1'))
        @email_server.deliveries.should be_empty
      end.should_not change(MList::Mail, :count)
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