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

  it 'should destroy dependent messages, so that they may clean up email' do
    MList::Thread.reflections[:messages].options[:dependent].should == :destroy
  end
end

describe MList::Thread, 'tree' do
  before do
    @messages = (1..5).map {|i| m = MList::Message.new; m.id = i; m}
    @messages[1].parent_id = @messages[0].id
    @messages[2].parent_id = @messages[1].id
    @messages[3].parent_id = @messages[0].id
    @messages[4].parent_id = @messages[3].id

    @thread = MList::Thread.new
    stub(@thread).messages {@messages}

    @tree = @thread.tree
  end

  it 'should answer the first message as the root of the tree' do
    @tree.should == @messages[0]
  end

  it 'should connect the nodes into a tree' do
    @tree.children.should == [@messages[1], @messages[3]]
  end

  it 'should connect next and previous to each node' do
    @tree.previous.should be_nil
    @tree.next.should == @messages[1]
    @tree.next.previous.should == @messages[0]
    @tree.next.next.should == @messages[2]
    @tree.next.next.next.should == @messages[3]
  end

  it 'should know if a message is the root' do
    @tree.root?.should be_true
    @tree.next.root?.should be_false
  end

  it 'should know if a message is a leaf' do
    @tree.leaf?.should be_false
    @tree.next.leaf?.should be_false
    @tree.next.next.leaf?.should be_true
  end

  it 'should answer when a message is last in the thread' do
    @thread.first?(@messages[0]).should be_true
    @thread.first?(@messages[1]).should be_false
    @thread.first?(@messages[2]).should be_false
  end

  it 'should answer when a message is last in the thread' do
    @thread.last?(@messages[0]).should be_false
    @thread.last?(@messages[1]).should be_false
    @thread.last?(@messages[4]).should be_true
  end

  it 'should answer the message next to given' do
    @thread.next(@messages[0]).should == @messages[1]
    @thread.next(@messages[2]).should == @messages[3]
    @thread.next(@messages[4]).should be_nil
  end

  it 'should answer the message previous to given' do
    @thread.previous(@messages[0]).should be_nil
    @thread.previous(@messages[2]).should == @messages[1]
  end
end
