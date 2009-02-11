require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'mlist/manager/database'

describe MList do
  def forward_email(tmail)
    simple_matcher('forward email') do |email_server|
      lambda do
        lambda do
          email_server.receive(tmail)
        end.should_not change(email_server.deliveries, :size)
      end.should_not store_message
    end
  end
  
  def store_message
    simple_matcher('store message') do |block|
      thread_count, message_count = MList::Thread.count, MList::Message.count
      block.call
      MList::Thread.count == thread_count + 1 && MList::Message.count == message_count + 1
    end
  end
  
  def start_new_thread(tmail)
    simple_matcher('start new thread') do |email_server|
      delivery_count = email_server.deliveries.size
      thread_count = MList::Thread.count
      message_count = MList::Message.count
      email_server.receive(tmail)
      email_server.deliveries.size > delivery_count &&
        MList::Thread.count == (thread_count + 1) &&
        MList::Message.count == (message_count + 1)
    end
  end
  
  dataset do
    @list_manager = MList::Manager::Database.new
    @list_one = @list_manager.create_list('list_one@example.com')
    @list_one.subscribe('adam@nomail.net')
    @list_one.subscribe('tom@example.com')
    @list_one.subscribe('dick@example.com')
    
    @list_two = @list_manager.create_list('list_two@example.com')
    @list_two.subscribe('adam@nomail.net')
    @list_two.subscribe('jane@example.com')
    
    @list_three = @list_manager.create_list('empty@example.com')
    @list_three.subscribe('adam@nomail.net')
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
  
  it 'should have threads and mail_lists updated_at set to last message receive time' do
    now = Time.now
    stub(Time).now {now}
    @email_server.receive(tmail_fixture('single_list'))
    MList::MailList.last.updated_at.to_s.should == now.to_s
    MList::Thread.last.updated_at.to_s.should == now.to_s
    
    later = 5.days.from_now
    stub(Time).now {later}
    @email_server.receive(tmail_fixture('single_list_reply'))
    MList::MailList.last.updated_at.to_s.should == later.to_s
    MList::Thread.last.updated_at.to_s.should == later.to_s
  end
  
  it 'should associate manager lists to mlist mail lists when they are ActiveRecord instances' do
    @email_server.receive(tmail_fixture('single_list'))
    mail_list = MList::MailList.last
    mail_list.manager_list.should == @list_one
    mail_list.manager_list_identifier.should == @list_one.list_id
  end
  
  it 'should not forward mail that has been on this server before' do
    @email_server.should_not forward_email(tmail_fixture('x-beenthere'))
  end
  
  it 'should not forward mail when there are no recipients' do
    tmail = tmail_fixture('single_list')
    tmail.to = @list_three.address
    @email_server.should_not forward_email(tmail)
  end
  
  it 'should not forward mail from non-subscriber and notify manager list' do
    tmail = tmail_fixture('single_list')
    tmail.from = 'unknown@example.com'
    stub(@list_manager).lists(is_a(MList::Email)) { [@list_one] }
    mock(@list_one).non_subscriber_post(is_a(MList::Email))
    @email_server.should_not forward_email(tmail)
  end
  
  it 'should not forward mail from non-subscriber when inactive and notify as non-subscriber' do
    tmail = tmail_fixture('single_list')
    tmail.from = 'unknown@example.com'
    do_not_call(@list_one).active?
    stub(@list_manager).lists(is_a(MList::Email)) { [@list_one] }
    mock(@list_one).non_subscriber_post(is_a(MList::Email))
    @email_server.should_not forward_email(tmail)
  end
  
  it 'should not forward mail from blocked subscriber, notify the subscriber using list manager notifier' do
    subscriber = MList::Manager::Database::Subscriber.find_by_email_address('adam@nomail.net')
    tmail = tmail_fixture('single_list')
    mock(@list_one).active? {true}
    mock(@list_one).blocked?(subscriber) { true }
    stub(@list_manager).lists(is_a(MList::Email)) { [@list_one] }
    lambda do
      @email_server.receive(tmail)
      response_tmail = @email_server.deliveries.last
      response_tmail.header_string('from').should == 'mlist-list_one@example.com'
      response_tmail.header_string('to').should == 'adam@nomail.net'
      response_tmail.header_string('x-mlist-loop').should == 'notice'
      response_tmail.header_string('x-mlist-notice').should == 'subscriber_blocked'
    end.should_not store_message
  end
  
  it 'should not forward mail to inactive list and notify manager list' do
    tmail = tmail_fixture('single_list')
    mock(@list_one).active? { false }
    stub(@list_manager).lists(is_a(MList::Email)) { [@list_one] }
    mock(@list_one).inactive_post(is_a(MList::Email))
    @email_server.should_not forward_email(tmail)
  end
  
  it 'should report unrecognized email to list manager' do
    tmail = tmail_fixture('single_list')
    stub(@list_manager).lists(is_a(MList::Email)) { [] }
    mock(@list_manager).no_lists_found(is_a(MList::Email))
    @email_server.should_not forward_email(tmail)
  end
  
  it 'should report bounces to the list manager' do
    stub(@list_manager).lists(is_a(MList::Email)) { [@list_one] }
    mock(@list_one).bounce(is_a(MList::Email))
    @email_server.should_not forward_email(tmail_fixture('bounces/1'))
  end
  
  describe 'single list' do
    before do
      @tmail_post = tmail_fixture('single_list')
      @email_server.receive(@tmail_post)
    end
    
    it 'should forward emails that are sent to a mailing list' do
      @email_server.deliveries.size.should == 1
      email = @email_server.deliveries.first
      email.should have_address(:to, 'list_one@example.com')
      # bcc fields are not in the headers of delivered emails
      email.should have_address(:'reply-to', 'list_one@example.com')
    end
    
    it 'should start a new thread for a new email' do
      thread = MList::Thread.last
      thread.messages.first.email.tmail.should equal_tmail(@tmail_post)
    end
    
    it 'should add to an existing thread when reply email' do
      message = MList::Message.last
      reply_tmail = tmail_fixture('single_list_reply', 'in-reply-to' => "<#{message.identifier}>")
      @email_server.receive(reply_tmail)
      thread = MList::Thread.last
      thread.messages.size.should be(2)
    end
    
    it 'should associate parent message when reply email' do
      message = MList::Message.last
      @email_server.receive(tmail_fixture('single_list_reply', 'in-reply-to' => "<#{message.identifier}>"))
      reply = MList::Message.last
      reply.parent_identifier.should == message.identifier
      reply.parent.should == message
    end
    
    it 'should not associate a parent when not a reply' do
      tmail = tmail_fixture('single_list')
      tmail['message-id'] = 'asdfasdfj'
      tmail['subject'] = 'other thing'
      @email_server.should start_new_thread(tmail)
    end
    
    it 'should store subscriber address with messages' do
      MList::Message.last.subscriber_address.should == 'adam@nomail.net'
    end
    
    it 'should associate subscriber to messages when they are ActiveRecord instances' do
      MList::Message.last.subscriber.should == MList::Manager::Database::Subscriber.find_by_email_address('adam@nomail.net')
    end
  end
  
  describe 'multiple lists' do
    before do
      @tmail_post = tmail_fixture('multiple_lists')
      @email_server.receive(@tmail_post)
    end
    
    it 'should forward emails that are sent to a mailing list' do
      @email_server.deliveries.size.should == 2
      
      email = @email_server.deliveries.first
      email.should have_address(:to, 'list_one@example.com')
      # bcc fields are not in the headers of delivered emails
      email.should have_address(:'reply-to', 'list_one@example.com')
      
      email = @email_server.deliveries.last
      email.should have_address(:to, 'list_two@example.com')
      # bcc fields are not in the headers of delivered emails
      email.should have_address(:'reply-to', 'list_two@example.com')
    end
    
    it 'should start a new thread for each list, both referencing the same email' do
      threads = MList::Thread.find(:all)
      threads[0].messages.first.email.should == threads[1].messages.first.email
    end
  end
end