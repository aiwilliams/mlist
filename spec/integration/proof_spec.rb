require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'mlist/manager/database'

describe MList do
  dataset do
    subscriber_addresses = %w(adam@nomail.net adam@example.net)
    
    @list_manager = MList::Manager::Database.new
    Dir[email_fixtures_path('integration/list*')].each do |list_path|
      list = @list_manager.create_list("#{File.basename(list_path)}@example.com")
      subscriber_addresses.each {|a| list.subscribe(a)}
    end
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
  
  it 'should place messages in threads and threads in lists' do
    Dir[email_fixtures_path('integration/list*')].each do |list_path|
      list = MList::Manager::Database::List.find_by_address(File.basename(list_path) + '@example.com')
      Dir[File.join(list_path, 'thread*')].each do |thread_path|
        email_paths = Dir[File.join(thread_path, '*.eml')]
        @email_server.should start_thread(TMail::Mail.load(email_paths.shift))
        email_paths.each do |email_path|
          tmail = TMail::Mail.load(email_path)
          expected = email_path =~ %r{\d+\.eml\Z} ? :should : :should_not
          @email_server.send expected, accept_message(tmail)
        end
      end
    end
  end
  
  def accept_message(tmail)
    simple_matcher("to receive message from #{tmail.header_string('from')}") do |email_server|
      message_count_start = MList::Message.count
      email_server.receive(tmail)
      MList::Message.count == message_count_start + 1
    end
  end
  
  def start_thread(tmail)
    simple_matcher("to begin thread from #{tmail.header_string('from')}") do |email_server|
      message_count_start = MList::Message.count
      thread_count_start = MList::Thread.count
      email_server.receive(tmail)
      MList::Message.count == message_count_start + 1
      MList::Thread.count == thread_count_start + 1
    end
  end
end