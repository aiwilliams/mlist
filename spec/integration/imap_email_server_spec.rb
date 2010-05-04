require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'mlist/email_server/imap'

describe MList::EmailServer::Imap, 'execute' do
  it 'should use the provided credentials when connecting' do
    imap_server = 'mock_imap_server'
    mock(Net::IMAP).new('host', 993, true) { imap_server }
    mock(imap_server).login('aahh', 'eeya')

    imap = MList::EmailServer::Imap.new(
      :server => 'host', :port => 993, :ssl => true,
      :username => 'aahh', :password => 'eeya'
    )
    imap.connect
  end

  it 'should connect, process the folders, disconnect on execution' do
    imap = MList::EmailServer::Imap.new({})
    mock(imap).connect
    mock(imap).process_folders
    mock(imap).disconnect
    imap.execute
  end
end

describe MList::EmailServer::Imap, 'processing' do
  before do
    @imap_server = 'mock_imap_server'
    @imap = MList::EmailServer::Imap.new({:archive_folder => 'Archive'})
    @imap.instance_variable_set('@imap', @imap_server)
  end

  it 'should process the provided folders' do
    imap = MList::EmailServer::Imap.new(:source_folders => ['Inbox', 'Spam'])
    mock(imap).process_folder('Inbox')
    mock(imap).process_folder('Spam')
    imap.process_folders
  end

  it 'should select the folder, process each message, close the folder' do
    message_ids = [1,2]
    mock(@imap_server).select('folder')
    mock(@imap_server).search(['NOT','DELETED']) { message_ids }
    mock(@imap_server).close
    mock(@imap).process_message_id(1)
    mock(@imap).archive_message_id(1)
    mock(@imap).process_message_id(2)
    mock(@imap).archive_message_id(2)
    @imap.process_folder('folder')
  end

  it 'should process the RFC822 message content' do
    mock(@imap_server).fetch(1, 'RFC822').mock![0].mock!.attr.mock!['RFC822'].returns('email content')
    mock(@imap).process_message('email content')
    @imap.process_message_id(1)
  end

  it 'should not blow up if an RFC822 does not exist' do
    mock(@imap_server).fetch(1, 'RFC822') { nil }
    lambda { @imap.process_message_id(1) }.should_not raise_error
  end

  it 'should wrap up RFC822 content in a TMail::Mail object' do
    tmail = 'mock_tmail'
    mock(TMail::Mail).parse('email content') { tmail }
    mock(@imap).receive(tmail)
    @imap.process_message('email content')
  end

  it 'should archive to the specified folder' do
    mock(@imap_server).copy(1, 'Archive')
    mock(@imap_server).store(1, '+FLAGS', [:Deleted])
    @imap.archive_message_id(1)
  end
end
