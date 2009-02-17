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
    @message.subject = '[List Label] The new Chrome Browser from Google'
    @message.subject_for_reply.should == 'Re: [List Label] The new Chrome Browser from Google'
    
    @message.subject = 'Re: [List Label] The new Chrome Browser from Google'
    @message.subject_for_reply.should == 'Re: [List Label] The new Chrome Browser from Google'
  end
  
  it 'should save the associated email' do
    @message.save!
    @message = MList::Message.find(@message.id)
    @message.email.source.should == email_fixture('single_list')
  end
  
  it 'should delete the email when message destroyed' do
    @message.save!
    @message.destroy
    MList::Email.exists?(@email).should be_false
  end
  
  it 'should not delete the email if other messages reference it' do
    @message.save!
    MList::Message.create!(:mail_list_id => 234234, :email => @email)
    @message.destroy
    MList::Email.exists?(@email).should be_true
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
  
  it 'should work with multipart/related, no text part' do
    message_from_tmail('content_types/multipart_related_no_text_plain').text.should == %(I don't really have much to say, so I'm going to share some random things I saw today:

I saw this guy on twitter.com, and he looks pretty chill:

I found this sweet url, and it's not dirty!: 

I found out that if I call our Skype phone from Skype on my laptop, my laptop will give me the ability to answer the call I am placing. Freaky!

Here is what my rating star widget looks like:

What's with the dashes and tildes?

Yeah, what is going on with that. They don't even match.
-~----~~----~----~----~----~---~~-~----~------~--~-~-
vs
--~--~---~~----~--~----~-----~~~----~---~---~--~-~--~


Good job with this!

-Steve)
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