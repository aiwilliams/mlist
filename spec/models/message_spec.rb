require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Message, 'parent_identifier' do
  before do
    @mail_list = MList::MailList.new
    @parent_message = MList::Message.new(:mail_list => @mail_list, :tmail => tmail_fixture('single_list'))
    @message = MList::Message.new(:mail_list => @mail_list, :tmail => tmail_fixture('single_list_reply'))
  end
  
  it 'should be in-reply-to field when present' do
    @message.parent_identifier.should == @parent_message.identifier
  end
  
  it 'should be references field if present and no in-reply-to' do
    @message.delete_header('in-reply-to')
    @message.parent_identifier.should == @parent_message.identifier
  end
  
  it 'should disregard references that are not in the list'
  
  it 'should be based on subject if present and no in-reply-to or references' do
    mock(@mail_list.messages).find(
      :first, :conditions => ['messages.subject = ?', 'Test'],
      :order => 'created_at asc'
    ) {@parent_message}
    
    @message.delete_header('in-reply-to')
    @message.delete_header('references')
    @message.parent_identifier.should == @parent_message.identifier
  end
end