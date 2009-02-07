require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Message do
  include MList::Util::EmailHelpers
  
  before do
    @tmail = tmail_fixture('single_list')
    @email = MList::Email.new(:tmail => @tmail)
    @message = MList::Message.new(:email => @email)
  end
  
  it 'should capture the mailer header' do
    @message.mailer.should == 'Apple Mail (2.929.2)'
  end
  
  it 'should capture the subject' do
    @message.subject.should == 'Test'
  end
  
  it 'should not modify the original email' do
    mock(@email)
    @message.subject = 'modified'
    @message.mailer = 'modified'
    @message.identifier = 'modified'
  end
  
  it 'should answer a subject suitable for replies' do
    @message.subject = 'Re: [List Label] Re: The new Chrome Browser from Google'
    @message.subject_for_reply.should == 'Re: The new Chrome Browser from Google'
  end
  
  it 'should save the associated email' do
    @message.save!
    @message = MList::Message.find(@message.id)
    @message.email.source.should == @tmail.to_s
  end
  
  describe 'delivery tmail' do
    it 'should capture the message-id' do
      delivery_tmail = @message.to_tmail
      delivery_message_id = remove_brackets(delivery_tmail.header_string('message-id'))
      delivery_message_id.should_not == 'F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative.com'
      @message.identifier.should_not be_blank
      @message.identifier.should == delivery_message_id
    end
  end
end

describe MList::Message, 'text' do
  def message_from_tmail(path)
    tmail = tmail_fixture(path)
    email = MList::Email.new(:tmail => tmail)
    MList::Message.new(:email => email)
  end
  
  it 'should work with text/plain' do
    message_from_tmail('content_types/text_plain').text.should == 'Hello there'
  end
  
  it 'should work with multipart/alternative, simple' do
    message_from_tmail('content_types/multipart_alternative_simple').text.should ==
      "This is just a simple test.\n\nThis line should be bold.\n\nThis line should be italic."
  end
  
  it 'should work with mutltipart/mixed, outlook' do
    message_from_tmail('content_types/multipart_mixed_outlook').text.should ==
      "This is a simple test."
  end
  
  it 'should answer text suitable for reply' do
    message_from_tmail('content_types/text_plain').text_for_reply.should ==
      email_fixture('content_types/text_plain_reply.txt')
  end
  
  it 'should answer html suitable for reply' do
    message_from_tmail('content_types/text_plain').html_for_reply.should ==
      email_fixture('content_types/text_plain_reply.html')
  end
end