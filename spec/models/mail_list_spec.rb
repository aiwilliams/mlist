require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::MailList do
  include MList::List
  
  before do
    stub(self).label       {'Discussions'}
    stub(self).address     {'list_one@example.com'}
    stub(self).list_id     {'list_one@example.com'}
    stub(self).subscribers {[
      MList::EmailSubscriber.new('adam@nomail.net'),
      MList::EmailSubscriber.new('john@example.com')
    ]}
    
    @outgoing_server = MList::EmailServer::Fake.new
    @mail_list = MList::MailList.create!(
      :manager_list => self,
      :outgoing_server => @outgoing_server)
  end
  
  it 'should not require the manager list be an ActiveRecord type' do
    @mail_list.list.should == self
    @mail_list.manager_list.should be_nil
  end
  
  it 'should have messages counted' do
    MList::Message.reflect_on_association(:mail_list).counter_cache_column.should == :messages_count
    MList::MailList.column_names.should include('messages_count')
  end
  
  it 'should have threads counted' do
    MList::Thread.reflect_on_association(:mail_list).counter_cache_column.should == :threads_count
    MList::MailList.column_names.should include('threads_count')
  end
  
  describe 'post' do
    it 'should allow posting a new message to the list' do
      lambda do
        lambda do
          @mail_list.post(
            :subscriber => subscribers.first,
            :subject => "I'm a Program!",
            :text => 'Are you a programmer or what?'
          )
        end.should change(MList::Message, :count).by(1)
      end.should change(MList::Thread, :count).by(1)
      
      tmail = @outgoing_server.deliveries.last
      tmail.subject.should =~ /I'm a Program!/
      tmail.from.should == ['adam@nomail.net']
    end
    
    it 'should answer the message for use by the application' do
      @mail_list.post(
        :subscriber => subscribers.first,
        :subject => "I'm a Program!",
        :text => 'Are you a programmer or what?'
      ).should be_instance_of(MList::Message)
    end
    
    it 'should allow posting a reply to an existing message' do
      @mail_list.process_email(MList::EmailServer::Email.new(tmail_fixture('single_list')))
      existing_message = @mail_list.messages.last
      lambda do
        lambda do
          @mail_list.post(
            :reply_to_message => existing_message,
            :subscriber => subscribers.first,
            :text => 'I am a programmer too, dude!'
          )
        end.should change(MList::Message, :count).by(1)
      end.should_not change(MList::Thread, :count)
      new_message = MList::Message.last
      new_message.subject.should == "Re: Test"
    end
    
    it 'should not associate a posting to a parent if not reply' do
      @mail_list.process_email(MList::EmailServer::Email.new(tmail_fixture('single_list')))
      lambda do
        lambda do
          @mail_list.post(
            :subscriber => subscribers.first,
            :subject => 'Test',
            :text => 'It is up to the application to provide reply_to'
          )
        end.should change(MList::Message, :count).by(1)
      end.should change(MList::Thread, :count).by(1)
      message = MList::Message.last
      message.parent.should be_nil
      message.parent_identifier.should be_nil
    end
    
    it 'should capture the message-id of delivered email' do
      pending 'restructuring of message'
      message = @mail_list.post(
        :subscriber => subscribers.first,
        :subject => 'Test',
        :text => 'Email must have a message id for threading'
      )
      message.identifier.should_not be_nil
    end
  end
  
  describe 'parent identifier' do
    before do
      @parent_message = MList::Message.new(:tmail => tmail_fixture('single_list'))
      @message = MList::Message.new(:tmail => tmail_fixture('single_list_reply'))
    end
    
    it 'should be in-reply-to field when present' do
      @mail_list.parent_identifier(@message).should == @parent_message.identifier
    end
    
    it 'should be references field if present and no in-reply-to' do
      @message.delete_header('in-reply-to')
      @mail_list.parent_identifier(@message).should == @parent_message.identifier
    end
    
    it 'should disregard references that are not in the list'
    
    describe 'using subject' do
      before do
        @message.delete_header('in-reply-to')
        @message.delete_header('references')
        
        mock(@mail_list.messages).find(
          :first, :conditions => ['mlist_messages.subject = ?', 'Test'],
          :order => 'created_at asc'
        ) {@parent_message}
      end
      
      it 'should happen if present and no in-reply-to or references' do
        @mail_list.parent_identifier(@message).should == @parent_message.identifier
      end
      
      ['RE: [list name] Re: Test', 'Re: [list name] Re: [list name] Test'].each do |subject|
        it "should handle '#{subject}'" do
          @message.subject = subject
          @mail_list.parent_identifier(@message).should == @parent_message.identifier
        end
      end
    end
  end
  
  describe 'delivery' do
    def process_post
      @mail_list.process_email(MList::EmailServer::Email.new(@tmail_post))
      @outgoing_server.deliveries.last
    end
    
    before do
      @tmail_post = tmail_fixture('single_list')
    end
    
    it 'should set x-beenthere on emails it delivers to keep from re-posting them' do
      process_post.should have_header('x-beenthere', 'list_one@example.com')
    end
    
    it 'should not remove any existing x-beenthere headers' do
      @tmail_post['x-beenthere'] = 'somewhere@nomain.net'
      process_post.should have_header('x-beenthere', %w(list_one@example.com somewhere@nomain.net))
    end
    
    it 'should not modify existing headers' do
      @tmail_post['x-something-custom'] = 'existing'
      process_post.should have_header('x-something-custom', 'existing')
    end
    
    it 'should prepend the list label to the subject of messages' do
      process_post.subject.should == '[Discussions] Test'
    end
    
    it 'should move the list label to the front of subjects that already include the label' do
      @tmail_post.subject = 'Re: [Discussions] Test'
      process_post.subject.should == '[Discussions] Re: Test'
    end
    
    it 'should remove multiple occurrences of Re:' do
      @tmail_post.subject = 'Re: [Discussions] Re: Test'
      process_post.subject.should == '[Discussions] Re: Test'
    end
    
    it 'should capture the new message-ids' do
      pending 'a restructuring of email content out of message'
      delivered = process_post
      delivered.header_string('message-id').should_not be_blank
      delivered.header_string('message-id').should_not match(/F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative\.com/)
    end
    
    it 'should maintain the content-id part headers (inline images, etc)' do
      @tmail_post = tmail_fixture('embedded_content')
      process_post.parts[1].parts[1]['content-id'].to_s.should == "<CF68EC17-F8ED-478A-A4A1-AEBF165A8830/bg_pattern.jpg>"
    end
    
    it 'should add standard list headers when they are available' do
      stub(self).help_url        {'http://list_manager.example.com/help'}
      stub(self).subscribe_url   {'http://list_manager.example.com/subscribe'}
      stub(self).unsubscribe_url {'http://list_manager.example.com/unsubscribe'}
      stub(self).owner_url       {"<mailto:list_manager@example.com>\n(Jimmy Fish)"}
      stub(self).archive_url     {'http://list_manager.example.com/archive'}
      
      process_post.should have_headers(
        'list-id'          => "list_one@example.com",
        'list-help'        => "<#{help_url}>",
        'list-subscribe'   => "<#{subscribe_url}>",
        'list-unsubscribe' => "<#{unsubscribe_url}>",
        'list-post'        => "<#{address}>",
        'list-owner'       => '<mailto:list_manager@example.com>(Jimmy Fish)',
        'list-archive'     => "<#{archive_url}>",
        'sender'           => 'mlist-list_one@example.com',
        'errors-to'        => 'mlist-list_one@example.com'
      )
    end
    
    it 'should not add list headers that are not available or nil' do
      stub(self).help_url {nil}
      delivery = process_post
      delivery.should_not have_header('list-help')
      delivery.should_not have_header('list-subscribe')
    end
    
    it 'should append the list footer to the text/plain part of emails'
  end
end