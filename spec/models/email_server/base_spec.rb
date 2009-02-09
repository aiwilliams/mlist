require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MList::EmailServer::Base do
  before do
    @email_server = MList::EmailServer::Fake.new(:domain => 'test.host')
  end
  
  it 'should provide unique message id generator' do
    @email_server.generate_message_id.should match(/([a-f0-9]+-){4,}[a-f0-9]+@test.host/)
  end
end