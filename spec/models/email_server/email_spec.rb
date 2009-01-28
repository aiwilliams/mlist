require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MList::EmailServer::Email do
  before do
    @tmail = tmail_fixture('single_list')
    @email = MList::EmailServer::Email.new(@tmail)
  end
  
  it 'should downcase the from address' do
    @tmail.from = 'ALL_Down_CaSe@NOmail.NET'
    @email.from_address.should == 'all_down_case@nomail.net'
  end
  
  it 'should downcase list addresses' do
    @tmail.to = 'ALL_Down_CaSe@NOmail.NET, ALL_Down_CaSe@YESmail.NET'
    @email.list_addresses.should == %w(all_down_case@nomail.net all_down_case@yesmail.net)
  end
end