require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'mlist/email_server/pop'

describe MList::EmailServer::Pop, 'execute' do
  before do
    @mails = []
    @pop = Object.new
    stub(@pop).mails { @mails }
    stub(@pop).start do |username, password, block|
      block.call @pop
    end
    stub(Net::POP3).new { @pop }
    @pop_server = MList::EmailServer::Pop.new({})
  end
  
  it 'should delete email after successfully receiving' do
    message = OpenStruct.new(:pop => email_fixture('single_list'))
    mock(message).delete
    @mails << message
    @pop_server.execute
  end
end