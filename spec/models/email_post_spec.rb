require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::EmailPost do
  before do
    @subscriber = MList::EmailSubscriber.new('john@example.com')
    @post = MList::EmailPost.new({
      :subscriber => @subscriber,
      :subject => "I'm a Program!",
      :text => "My simple message that isn't too short"
    })
  end
  
  it 'should send include html and text when both provided' do
    @post.html = "<p>My simple message</p>"
    
    tmail = @post.to_tmail
    tmail.content_type.should == 'multipart/alternative'
    tmail.parts.size.should == 2
    
    # The first part should be the least desirable...
    part = tmail.parts.first
    part.content_type.should == 'text/plain'
    
    # And the last should be the best alternative.
    part = tmail.parts.last
    part.content_type.should == 'text/html'
  end
  
  it "should default the mailer to 'MList Client Application'" do
    @post.to_tmail['x-mailer'].to_s.should == 'MList Client Application'
  end
  
  it 'should use the given mailer' do
    @post.mailer = 'My Program'
    @post.to_tmail['x-mailer'].to_s.should == 'My Program'
  end
  
  it 'should assign the identifier it is in reply-to' do
    message = MList::Message.new(:tmail => tmail_fixture('single_list'))
    @post.reply_to_message = message
    @post.to_tmail.in_reply_to.should == ["<#{message.identifier}>"]
  end
end

describe MList::EmailPost, 'validations' do
  before do
    subscriber = MList::EmailSubscriber.new('john@example.com')
    @post = MList::EmailPost.new({
      :subscriber => subscriber,
      :subject => "I'm a Program!",
      :text => "My simple message that isn't too short"
    })
  end
  
  it 'should be valid with subject and a few words' do
    @post.should be_valid
  end
  
  it 'should require text' do
    @post.text = ''
    @post.should_not be_valid
    @post.errors[:text].should_not be_nil
  end
  
  it 'should require at least 25 characters of text' do
    @post.text = 'A' * 24
    @post.should_not be_valid
    @post.errors[:text].should_not be_nil
    
    @post.text = 'A' * 25
    @post.should be_valid
    @post.errors[:text].should be_nil
  end
  
  it 'should require subject' do
    @post.subject = ''
    @post.should_not be_valid
    @post.errors[:subject].should_not be_nil
  end
end