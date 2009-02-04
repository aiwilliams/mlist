require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Email do
  before do
    @tmail = tmail_fixture('single_list')
    @email = MList::Email.new(:tmail => @tmail)
  end
  
  it 'should store the source email content' do
    @email.source.should == @tmail.to_s
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

describe MList::Email, 'parent identifier' do
  def email(path)
    MList::Email.new(:tmail => tmail_fixture(path))
  end
  
  it 'should be nil if none found' do
    email('single_list').parent_identifier.should be_nil
  end
  
  it 'should be in-reply-to field when present' do
    email('single_list_reply').parent_identifier.should == 'F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative.com'
  end
  
  it 'should be references field if present and no in-reply-to' do
    tmail = tmail_fixture('single_list_reply')
    tmail['in-reply-to'] = nil
    MList::Email.new(:tmail => tmail).parent_identifier.should == 'F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative.com'
  end
  
  it 'should disregard references that are not found in the provided mail list'
  
  describe 'by subject' do
    def search_subject(subject = nil)
      simple_matcher("search by the subject '#{subject}'") do |email|
        if subject
          mock(@mail_list.messages).find(
            :first, :select => 'identifier',
            :conditions => ['mlist_messages.subject = ?', subject],
            :order => 'created_at asc'
          ) {@parent_message}
        else
          do_not_call(@mail_list.messages).find
        end
        email.parent_identifier(@mail_list)
        !subject.nil?
      end
    end
    
    before do
      @parent_message = MList::Message.new
      @mail_list = MList::MailList.new
      @reply_tmail = tmail_fixture('single_list')
      @reply_email = MList::Email.new(:tmail => @reply_tmail)
    end
    
    it 'should be employed if it has "re:" in it' do
      @reply_tmail.subject = "Re: Test"
      @reply_email.should search_subject('Test')
    end
    
    it 'should not be employed when no "re:"' do
      @reply_email.should_not search_subject
    end
    
    ['RE: [list name] Re: Test', 'Re: [list name] Re: [list name] Test', '[list name] Re: Test'].each do |subject|
      it "should handle '#{subject}'" do
        @reply_tmail.subject = subject
        @reply_email.should search_subject('Test')
      end
    end
  end
end
