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
  
  it 'should answer a subject suitable for replies' do
    @message.subject = 'Re: [List Label] Re: The new Chrome Browser from Google'
    @message.subject_for_reply.should == 'Re: The new Chrome Browser from Google'
  end
end

describe MList::Message, 'text' do
  it 'should work with text/plain' do
    message = MList::Message.new(:tmail => tmail_fixture('content_types/text_plain'))
    message.text.should == 'Hello there'
  end
  
  it 'should work with multipart/alternative, simple' do
    message = MList::Message.new(:tmail => tmail_fixture('content_types/multipart_alternative_simple'))
    message.text.should == "This is just a simple test.\n\nThis line should be bold.\n\nThis line should be italic."
  end
  
  it 'should answer text suitable for reply' do
    message = MList::Message.new(:tmail => tmail_fixture('content_types/text_plain'))
    message.text_for_reply.should == email_fixture('content_types/text_plain_reply.txt')
  end
  
  it 'should answer html suitable for reply' do
    message = MList::Message.new(:tmail => tmail_fixture('content_types/text_plain'))
    message.html_for_reply.should == email_fixture('content_types/text_plain_reply.html')
  end
end