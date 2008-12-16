require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::List do
  include MList::List
  
  attr_accessor :address, :subscriptions
  
  before do
    self.address = 'list@example.com'
    self.subscriptions = [Object.new]
    subscriptions.each { |s| stub(s).address {'bob@example.com'} }
    
    @mail = MList::Mail.new(:tmail => TMail::Mail.new)
  end
  
  describe 'prepare_delivery' do
    it 'should set x-beenthere on emails it receives to keep from re-processing them' do
      prepare_delivery(@mail)
      @mail.should have_header('x-beenthere', 'list@example.com')
    end
  end
  
  it 'should not deliver mail when there are no subscriptions'
end