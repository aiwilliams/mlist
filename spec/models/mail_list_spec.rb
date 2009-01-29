require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::MailList do
  include MList::List
  
  before do
    stub(self).label       {'Discussions'}
    stub(self).address     {'list@example.com'}
    stub(self).list_id     {'list@example.com'}
    stub(self).subscribers {[MList::EmailSubscriber.new('bob@example.com')]}
    
    @mail_list = MList::MailList.new(:manager_list => self)
    @message = MList::Message.new(
      :mail_list => @mail_list,
      :tmail => tmail_fixture('single_list'),
      :subscriber => subscribers.first
    )
  end
  
  it 'should not require the manager list be an ActiveRecord type' do
    @mail_list.list.should == self
    @mail_list.manager_list.should be_nil
  end
  
  describe 'prepare_delivery' do
    it 'should set x-beenthere on emails it receives to keep from re-posting them' do
      @mail_list.prepare_delivery(@message)
      @message.should have_header('x-beenthere', 'list@example.com')
    end
    
    it 'should not remove any existing x-beenthere headers' do
      @message.write_header('x-beenthere', 'somewhere@nomain.net')
      @mail_list.prepare_delivery(@message)
      @message.tmail['x-beenthere'].size.should == 2
      @message.tmail['x-beenthere'].first.to_s.should == 'list@example.com'
      @message.tmail['x-beenthere'].last.to_s.should == 'somewhere@nomain.net'
    end
    
    it 'should not modify existing headers' do
      @message.write_header('x-something-custom', 'existing')
      @mail_list.prepare_delivery(@message)
      @message.tmail['x-something-custom'].to_s.should == 'existing'
    end
    
    it 'should prepend the list label to the subject of messages' do
      @mail_list.prepare_delivery(@message)
      @message.subject.should == '[Discussions] Test'
    end
    
    it 'should move the list label to the front of subjects that already include the label' do
      @message.subject = 'Re: [Discussions] Test'
      @mail_list.prepare_delivery(@message)
      @message.subject.should == '[Discussions] Re: Test'
    end
    
    it 'should remove multiple occurrences of Re:' do
      @message.subject = 'Re: [Discussions] Re: Test'
      @mail_list.prepare_delivery(@message)
      @message.subject.should == '[Discussions] Re: Test'
    end
    
    it 'should add standard list headers when they are available' do
      stub(self).help_url        {'http://list_manager.example.com/help'}
      stub(self).subscribe_url   {'http://list_manager.example.com/subscribe'}
      stub(self).unsubscribe_url {'http://list_manager.example.com/unsubscribe'}
      stub(self).owner_url       {"<mailto:list_manager@example.com>\n(Jimmy Fish)"}
      stub(self).archive_url     {'http://list_manager.example.com/archive'}
      
      @mail_list.prepare_delivery(@message)
      
      {
        'list-id'          => "list@example.com",
        'list-help'        => "<#{help_url}>",
        'list-subscribe'   => "<#{subscribe_url}>",
        'list-unsubscribe' => "<#{unsubscribe_url}>",
        'list-post'        => "<#{address}>",
        'list-owner'       => '<mailto:list_manager@example.com>(Jimmy Fish)',
        'list-archive'     => "<#{archive_url}>",
        'sender'           => 'mlist-list@example.com',
        'errors-to'        => 'mlist-list@example.com'
      }.each do |header, expected|
        @message.should have_header(header, expected)
      end
    end
    
    it 'should not add list headers that are not available or nil' do
      stub(self).help_url {nil}
      @mail_list.prepare_delivery(@message)
      %w(list-help list-subscribe).each do |header|
        @message.should_not have_header(header)
      end
    end
  end
end