require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::List do
  include MList::List
  
  attr_accessor :label, :address, :subscriptions
  attr_accessor :help_url, :subscribe_url,
                :unsubscribe_url, :owner_url, :archive_url
  
  before do
    self.label = 'Discussions'
    self.address = 'list@example.com'
    self.help_url = 'http://listman.example.com/help'
    self.subscribe_url = 'http://listman.example.com/subscribe'
    self.unsubscribe_url = 'http://listman.example.com/unsubscribe'
    self.owner_url = "<mailto:listman@example.com>\n(Jimmy Fish)"
    self.archive_url = 'http://listman.example.com/archive'
    
    self.subscriptions = [Object.new]
    
    subscriptions.each { |s| stub(s).address {'bob@example.com'} }
    
    @mail = MList::Mail.new(:tmail => TMail::Mail.new)
  end
  
  describe 'prepare_delivery' do
    before do
      prepare_delivery(@mail)
    end
    
    it 'should set x-beenthere on emails it receives to keep from re-processing them' do
      @mail.should have_header('x-beenthere', 'list@example.com')
    end
    
    it 'should not remove any existing x-beenthere headers'
    
    # http://www.jamesshuggins.com/h/web1/list-email-headers.htm
    it 'should add standard list headers' do
      {
        'List-Id' => "Discussions <list@example.com>",
        'List-Help' => "<#{help_url}>",
        'List-Subscribe' => "<#{subscribe_url}>",
        'List-Unsubscribe' => "<#{unsubscribe_url}>",
        'List-Post' => "<#{address}>",
        'List-Owner' => '<mailto:listman@example.com>(Jimmy Fish)',
        'List-Archive' => "<#{archive_url}>"
      }.each do |header, expected|
        @mail.should have_header(header, expected)
      end
    end
  end
  
  it 'should not deliver mail when there are no subscriptions'
end