require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'mlist/email_server/imap'

describe MList::EmailServer::Imap, 'settings' do
  it 'should use the provided credentials' do
    mock(Net::IMAP).new('host', 993, true) { mock('imap') }
    MList::EmailServer::Imap.new(:server => 'host', :port => 993, :ssl => true)
  end

  it 'should login with the provided credentials, process the folders, close on completion' do
    imap_server = Object.new
    stub(Net::IMAP).new { imap_server }

    mock(imap_server).login('aahh', 'eeya')
    mock(imap_server).close

    imap = MList::EmailServer::Imap.new(
      :username => 'aahh', :password => 'eeya'
    )
    mock(imap).process_folders
    imap.execute
  end

  it 'should process the provided folders' do
    imap_server = Object.new
    stub(Net::IMAP).new { imap_server }
    imap = MList::EmailServer::Imap.new(
      :source_folders => ['Inbox', 'Spam']
    )
    mock(imap).process_folder('Inbox')
    mock(imap).process_folder('Spam')
    imap.process_folders
  end
end

describe MList::EmailServer::Imap, 'processing' do
  before do
    @imap_server = 'mock_imap_server'
    stub(Net::IMAP).new { @imap_server }
    @imap = MList::EmailServer::Imap.new({:archive_folder => 'Archive'})
  end

  it 'should examine the specified folder and process all the messages' do
    message_ids = [1,2]
    mock(@imap_server).select('folder')
    mock(@imap_server).search(['ALL']) { message_ids }
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
