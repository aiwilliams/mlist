require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Thread do
  it 'should answer subject by way of the first message' do
    message = MList::Message.new(:mail_list => MList::MailList.new, :tmail => tmail_fixture('single_list'))
    thread = MList::Thread.new
    thread.messages << message
    thread.subject.should_not be_nil
    thread.subject.should == message.subject
  end
end