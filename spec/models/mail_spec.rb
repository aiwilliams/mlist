require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Mail, 'parent_identifier' do
  before do
    @mail_list = MList::MailList.new
    @parent_mail = MList::Mail.new(:mail_list => @mail_list, :tmail => email_fixture('single_list'))
    @mail = MList::Mail.new(:mail_list => @mail_list, :tmail => email_fixture('single_list_reply'))
  end
  
  it 'should be in-reply-to field when present' do
    @mail.parent_identifier.should == @parent_mail.identifier
  end
  
  it 'should be references field if present and no in-reply-to' do
    @mail.delete_header('in-reply-to')
    @mail.parent_identifier.should == @parent_mail.identifier
  end
  
  it 'should disregard references that are not in the list'
  
  it 'should be based on subject if present and no in-reply-to or references' do
    mock(@mail_list.mails).find(
      :first, :conditions => ['mails.subject = ?', 'Test'],
      :order => 'created_at asc'
    ) {@parent_mail}
    
    @mail.delete_header('in-reply-to')
    @mail.delete_header('references')
    @mail.parent_identifier.should == @parent_mail.identifier
  end
end