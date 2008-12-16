require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::List do
  include MList::List
  
  before do
    stub(self).label           {'Discussions'}
    stub(self).address         {'list@example.com'}
    stub(self).subscriptions   {[OpenStruct.new(:address => 'bob@example.com')]}
    
    @mail = MList::Mail.new(:tmail => TMail::Mail.new)
  end
  
  describe 'prepare_delivery' do
    it 'should set x-beenthere on emails it receives to keep from re-processing them' do
      prepare_delivery(@mail)
      @mail.should have_header('x-beenthere', 'list@example.com')
    end
    
    it 'should not remove any existing x-beenthere headers'
    
    it 'should add standard list headers when they are available' do
      stub(self).help_url        {'http://listman.example.com/help'}
      stub(self).subscribe_url   {'http://listman.example.com/subscribe'}
      stub(self).unsubscribe_url {'http://listman.example.com/unsubscribe'}
      stub(self).owner_url       {"<mailto:listman@example.com>\n(Jimmy Fish)"}
      stub(self).archive_url     {'http://listman.example.com/archive'}
      
      prepare_delivery(@mail)
      
      {
        'list-id' => "Discussions <list@example.com>",
        'list-help' => "<#{help_url}>",
        'list-subscribe' => "<#{subscribe_url}>",
        'list-unsubscribe' => "<#{unsubscribe_url}>",
        'list-post' => "<#{address}>",
        'list-owner' => '<mailto:listman@example.com>(Jimmy Fish)',
        'list-archive' => "<#{archive_url}>"
      }.each do |header, expected|
        @mail.should have_header(header, expected)
      end
    end
    
    it 'should not add list headers that are not available or nil' do
      stub(self).help_url {nil}
      prepare_delivery(@mail)
      %w(list-help list-subscribe).each do |header|
        @mail.should_not have_header(header)
      end
    end
  end
  
  it 'should not deliver mail when there are no subscriptions'
end