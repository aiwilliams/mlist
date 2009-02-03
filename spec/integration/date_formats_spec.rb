require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList, 'date formats' do
  specify 'mlist_reply_timestamp should handle single digit days and months' do
    Time.local(2009, 2, 3, 7).to_s(:mlist_reply_timestamp).should == 'Tue, Feb 3, 2009 at 7:00 AM'
  end
  
  specify 'mlist_reply_timestamp should handle double digit days and months' do
    Time.local(2009, 2, 13, 11).to_s(:mlist_reply_timestamp).should == 'Fri, Feb 13, 2009 at 11:00 AM'
    Time.local(2009, 2, 13, 14).to_s(:mlist_reply_timestamp).should == 'Fri, Feb 13, 2009 at 2:00 PM'
  end
end