require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MList::EmailServer::Email, 'list addresses' do
  it "should not answer addresses that are not in the email server's domain"
end