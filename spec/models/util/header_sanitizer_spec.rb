require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MList::Util::HeaderSanitizerHash do
  before do
    @sanitizer = MList::Util::HeaderSanitizerHash.new
  end
  
  %w(to cc bcc from reply-to).each do |header|
    it %Q{should escape " and \\ in address phrase for #{header}} do
      @sanitizer[header].call('UTF-8', '"Johnny " Dangerously \" <johnny@nomail.net>').should == ['"Johnny \" Dangerously \\\\" <johnny@nomail.net>']
    end
  end
  
  %w(sender errors-to).each do |header|
    it %Q{should escape " in address phrase for #{header}} do
      @sanitizer[header].call('UTF-8', '"Johnny " Dangerously \" <johnny@nomail.net>').should == '"Johnny \" Dangerously \\\\" <johnny@nomail.net>'
    end
  end
end