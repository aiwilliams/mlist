require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Email do
  before do
    @tmail = tmail_fixture('single_list')
    @email = MList::Email.new(:tmail => @tmail)
  end
  
  it 'should downcase the from address' do
    @tmail.from = 'ALL_Down_CaSe@NOmail.NET'
    @email.from_address.should == 'all_down_case@nomail.net'
  end
  
  it 'should downcase list addresses' do
    @tmail.to = 'ALL_Down_CaSe@NOmail.NET, ALL_Down_CaSe@YESmail.NET'
    @email.list_addresses.should == %w(all_down_case@nomail.net all_down_case@yesmail.net)
  end
  
  it 'should answer the subject of the email' do
    @email.subject.should == 'Test'
  end
  
  it 'should be careful to save true source of email' do
    @email = MList::Email.new(:tmail => tmail_fixture('embedded_content'))
    @email.save!
    @email.reload.source.should == email_fixture('embedded_content')
  end
  
  it 'should answer the Date of the email, created_at otherwise' do
    @email.date.should == Time.parse('Mon, 15 Dec 2008 00:38:31 -0500')
    @tmail['date'] = nil
    
    stub(Time).now { Time.local(2009,1,1) }
    @email.date.should == Time.local(2009,1,1)
    
    stub(Time).now { Time.local(2009,3,1) }
    @email.date.should == Time.local(2009,1,1)
    
    @email.created_at = Time.local(2009,2,1)
    @email.date.should == Time.local(2009,2,1)
  end
end