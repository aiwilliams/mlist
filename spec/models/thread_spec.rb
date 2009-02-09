require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::Thread do
  before do
    @messages = (1..3).map {|i| m = MList::Message.new; stub(m).subject {i.to_s}; m}
    @thread = MList::Thread.new
    stub(@thread).messages {@messages}
  end
  
  it 'should answer subject by way of the first message' do
    @thread.subject.should == '1'
  end
  
  it 'should have messages counted' do
    MList::Message.reflect_on_association(:thread).counter_cache_column.should == :messages_count
    MList::Thread.column_names.should include('messages_count')
  end
  
  it 'should answer when a message is last in the thread' do
    @thread.first?(@messages[0]).should be_true
    @thread.first?(@messages[1]).should be_false
    @thread.first?(@messages[2]).should be_false
  end
  
  it 'should answer when a message is last in the thread' do
    @thread.last?(@messages[0]).should be_false
    @thread.last?(@messages[1]).should be_false
    @thread.last?(@messages[2]).should be_true
  end
  
  it 'should answer the message next to given' do
    @thread.next(@messages[0]).should == @messages[1]
    @thread.next(@messages[2]).should be_nil
  end
  
  it 'should answer the message previous to given' do
    @thread.previous(@messages[0]).should be_nil
    @thread.previous(@messages[2]).should == @messages[1]
  end
end

describe MList::Thread, 'tree' do
  before do
    @messages = (1..5).map {|i| m = MList::Message.new; stub(m).subject {i.to_s}; m}
    @messages[1].parent = @messages[0]
    @messages[2].parent = @messages[1]
    @messages[4].parent = @messages[3]
    
    @thread = MList::Thread.new
    stub(@thread).messages {@messages}
  end
  
  it 'should answer the root nodes' do
    @thread.roots.should == [@messages[0], @messages[3]]
  end
  
  it 'should answer the children of a node' do
    @thread.children(@messages[0]).should == [@messages[1]]
    @thread.children(@messages[1]).should == [@messages[2]]
    @thread.children(@messages[2]).should == []
    @thread.children(@messages[3]).should == [@messages[4]]
  end
end