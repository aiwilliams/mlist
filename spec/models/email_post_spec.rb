require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::EmailPost do
  def tmail(attributes = {})
    subscriber = MList::EmailSubscriber.new('john@example.com')
    post = MList::EmailPost.new({
      :subscriber => subscriber,
      :subject => "I'm a Program!",
      :text => "My simple message"
    }.merge(attributes))
    post.tmail
  end
  
  it 'should send include html and text when both provided' do
    tmail = self.tmail(:html => "<p>My simple message</p>")
    
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
    self.tmail['x-mailer'].to_s.should == 'MList Client Application'
  end
  
  it 'should use the given mailer' do
    tmail = self.tmail(:mailer => 'My Program')
    tmail['x-mailer'].to_s.should == 'My Program'
  end
end