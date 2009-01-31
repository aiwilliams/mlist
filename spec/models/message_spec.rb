require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Message do
  before do
    @tmail = tmail_fixture('single_list')
    @message = MList::Message.new(:tmail => @tmail)
  end
  
  it 'should store the mailer header' do
    @message.mailer.should == 'Apple Mail (2.929.2)'
  end
  
  it 'should not modify the original mail content' do
    @message.write_header('x-whatever', 'something')
    @tmail['x-whatever'].should be_nil
  end
  
  it 'should store the original incoming email subject' do
    @message.subject.should == 'Test'
    @message.subject = 'modified'
    @message.subject.should == 'modified'
    @message.read_attribute(:subject).should == 'Test'
    @tmail.subject.should == 'Test'
  end
  
  it 'should not allow modification of the identifier, which represents the actual email message-id' do
    lambda do
      @message.identifier = 'hello'
    end.should raise_error
  end
end