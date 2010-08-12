require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MList::MailList do
  class ManagerList
    include MList::List
  end

  before do
    @manager_list = ManagerList.new
    stub(@manager_list).label       {'Discussions'}
    stub(@manager_list).address     {'list_one@example.com'}
    stub(@manager_list).list_id     {'list_one@example.com'}

    @subscriber_one = MList::EmailSubscriber.new('adam@nomail.net')
    @subscriber_two = MList::EmailSubscriber.new('john@example.com')
    stub(@manager_list).subscribers {[@subscriber_one, @subscriber_two]}

    @outgoing_server = MList::EmailServer::Fake.new
    @mail_list = MList::MailList.create!(
      :manager_list => @manager_list,
      :outgoing_server => @outgoing_server)
  end

  it 'should not require the manager list be an ActiveRecord type' do
    @mail_list.list.should == @manager_list
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

  it 'should delete email not referenced by other lists' do
    email_in_other = MList::Email.create!(:tmail => tmail_fixture('single_list'))
    email_not_other = MList::Email.create!(:tmail => tmail_fixture('single_list'))
    lambda do
      MList::Message.create!(:mail_list_id => 2342342, :email => email_in_other)
      @mail_list.process_email(email_in_other, @subscriber_one)
      @mail_list.process_email(email_not_other, @subscriber_one)
    end.should change(MList::Message, :count).by(3)
    @mail_list.destroy
    MList::Email.exists?(email_in_other).should be_true
    MList::Email.exists?(email_not_other).should be_false
  end

  describe 'post' do
    it 'should allow posting a new message to the list' do
      lambda do
        lambda do
          @mail_list.post(
            :subscriber => @subscriber_one,
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
        :subscriber => @subscriber_one,
        :subject => "I'm a Program!",
        :text => 'Are you a programmer or what?'
      ).should be_instance_of(MList::Message)
    end

    it 'should allow posting a reply to an existing message' do
      @mail_list.process_email(MList::Email.new(:tmail => tmail_fixture('single_list')), @subscriber_one)
      existing_message = @mail_list.messages.last
      lambda do
        lambda do
          @mail_list.post(
            :reply_to_message => existing_message,
            :subscriber => @subscriber_one,
            :text => 'I am a programmer too, dude!'
          )
        end.should change(MList::Message, :count).by(1)
      end.should_not change(MList::Thread, :count)
      new_message = MList::Message.last
      new_message.subject.should == "Re: Test"
    end

    it 'should not associate a posting to a parent if not reply' do
      @mail_list.process_email(MList::Email.new(:tmail => tmail_fixture('single_list')), @subscriber_one)
      lambda do
        lambda do
          @mail_list.post(
            :subscriber => @subscriber_one,
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
      message = @mail_list.post(
        :subscriber => @subscriber_one,
        :subject => 'Test',
        :text => 'Email must have a message id for threading')
      message.reload.identifier.should_not be_nil
    end

    it 'should copy the subscriber if desired' do
      @mail_list.post(
        :subscriber => @subscriber_one,
        :subject => 'Copy Me',
        :text => 'Email should be sent to subscriber if desired',
        :copy_sender => true)

      tmail = @outgoing_server.deliveries.last
      tmail.bcc.should include(@subscriber_one.rfc5322_email)
    end

    it 'should not copy the subscriber if undesired and list includes the subscriber' do
      # The MList::List implementor may include the sending subscriber
      stub(@manager_list).recipients {[@subscriber_one, @subscriber_two]}

      @mail_list.post(
        :subscriber => @subscriber_one,
        :subject => 'Do Not Copy Me',
        :text => 'Email should not be sent to subscriber if undesired',
        :copy_sender => false)

      tmail = @outgoing_server.deliveries.last
      tmail.bcc.should_not include(@subscriber_one.rfc5322_email)
    end
  end

  describe 'message storage' do
    def process_post
      @mail_list.process_email(MList::Email.new(:tmail => @post_tmail), @subscriber)
      MList::Message.last
    end

    before do
      @post_tmail = tmail_fixture('single_list')
      @subscriber = @subscriber_one
    end

    it 'should not include list label in subject' do
      @post_tmail.subject = '[Discussions] Test'
      process_post.subject.should == 'Test'
    end

    it 'should not include list label in reply subject' do
      @post_tmail.subject = 'Re: [Discussions] Test'
      process_post.subject.should == 'Re: Test'
    end

    it 'should not bother labels it does not understand in subject' do
      @post_tmail.subject = '[Ann] Test'
      process_post.subject.should == '[Ann] Test'
    end

    it 'should not bother labels it does not understand in reply subject' do
      @post_tmail.subject = 'Re: [Ann] Test'
      process_post.subject.should == 'Re: [Ann] Test'
    end

    it 'should be careful of multiple re:' do
      @post_tmail.subject = 'Re: [Ann] RE: Test'
      process_post.subject.should == 'Re: [Ann] Test'
    end
  end

  describe 'finding parent message' do
    def email(path)
      MList::Email.new(:tmail => tmail_fixture(path))
    end

    before do
      @parent_message = MList::Message.new
    end

    it 'should be nil if none found' do
      do_not_call(@mail_list.messages).find
      @mail_list.find_parent_message(email('single_list')).should be_nil
    end

    it 'should use in-reply-to field when present' do
      mock(@mail_list.messages).find(:first, :conditions => [
        'identifier = ?', 'F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative.com'
        ]) { @parent_message }
      @mail_list.find_parent_message(email('single_list_reply')).should == @parent_message
    end

    it 'should be references field if present and no in-reply-to' do
      tmail = tmail_fixture('single_list_reply')
      tmail['in-reply-to'] = nil
      mock(@mail_list.messages).find(:first,
        :conditions => ['identifier in (?)', ['F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative.com']],
        :order => 'created_at desc') { @parent_message }
      @mail_list.find_parent_message(MList::Email.new(:tmail => tmail)).should == @parent_message
    end

    describe 'by subject' do
      def search_subject(subject = nil)
        simple_matcher("search by the subject '#{subject}'") do |email|
          if subject
            mock(@mail_list.messages).find(
              :first,
              :conditions => ['subject = ?', subject],
              :order => 'created_at asc'
            ) {@parent_message}
          else
            do_not_call(@mail_list.messages).find
          end
          @mail_list.find_parent_message(email)
          !subject.nil?
        end
      end

      before do
        @parent_message = MList::Message.new
        @mail_list = MList::MailList.new
        stub(@mail_list).label { 'list name' }
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

  describe 'delivery' do
    include MList::Util::EmailHelpers

    def process_post
      @mail_list.process_email(MList::Email.new(:source => @post_tmail.to_s), @subscriber)
      @outgoing_server.deliveries.last
    end

    before do
      @post_tmail = tmail_fixture('single_list')
      @subscriber = @subscriber_one
    end

    it 'should be blind copied to recipients' do
      mock.proxy(@mail_list.messages).build(anything) do |message|
        mock(message.delivery).bcc=(%w(john@example.com))
        message
      end
      process_post
    end

    it 'should not deliver to addresses found in the to header' do
      @post_tmail.to = ['john@example.com', 'list_one@example.com']
      mock.proxy(@mail_list.messages).build(anything) do |message|
        mock(message.delivery).bcc=([])
        message
      end
      process_post
    end

    it 'should not deliver to addresses found in the cc header' do
      @post_tmail.cc = ['john@example.com']
      mock.proxy(@mail_list.messages).build(anything) do |message|
        mock(message.delivery).bcc=([])
        message
      end
      process_post
    end

    it 'should use list address as reply-to by default' do
      process_post.should have_header('reply-to', 'Discussions <list_one@example.com>')
    end

    it 'should use subscriber address as reply-to if list says to not use address' do
      mock(@manager_list).reply_to_list? { false }
      process_post.should have_header('reply-to', 'adam@nomail.net')
    end

    it 'should use the reply-to already in an email - should not override it' do
      @post_tmail['reply-to'] = 'theotheradam@nomail.net'
      process_post.should have_header('reply-to', 'theotheradam@nomail.net')
    end

    it 'should set x-beenthere on emails it delivers to keep from re-posting them' do
      process_post.should have_header('x-beenthere', 'list_one@example.com')
    end

    it 'should not remove any existing x-beenthere headers' do
      @post_tmail['x-beenthere'] = 'somewhere@nomail.net'
      process_post.should have_header('x-beenthere', %w(list_one@example.com somewhere@nomail.net))
    end

    it 'should not modify existing headers' do
      @post_tmail['x-something-custom'] = 'existing'
      process_post.should have_header('x-something-custom', 'existing')
    end

    it 'should delete Return-Receipt-To headers since they cause clients to spam the list (the sender address)' do
      @post_tmail['return-receipt-to'] = 'somewhere@nomail.net'
      process_post.should_not have_header('return-receipt-to')
    end

    it 'should not have any cc addresses' do
      @post_tmail['cc'] = 'billybob@anywhere.com'
      process_post.should_not have_header('cc')
    end

    it 'should prefix the list label to the subject of messages' do
      process_post.subject.should == '[Discussions] Test'
    end

    it 'should move the list label to the front of subjects that already include the label' do
      @post_tmail.subject = 'Re: [Discussions] Test'
      process_post.subject.should == 'Re: [Discussions] Test'
    end

    it 'should remove multiple occurrences of Re:' do
      @post_tmail.subject = 'Re: [Discussions] Re: Test'
      process_post.subject.should == 'Re: [Discussions] Test'
    end

    it 'should remove DomainKey-Signature headers so that we can sign the redistribution' do
      @post_tmail['DomainKey-Signature'] = "a whole bunch of junk"
      process_post.should_not have_header('domainkey-signature')
    end

    it 'should remove DKIM-Signature headers so that we can sign the redistribution' do
      @post_tmail['DKIM-Signature'] = "a whole bunch of junk"
      process_post.should_not have_header('dkim-signature')
    end

    it 'should capture the new message-ids' do
      delivered = process_post
      delivered.header_string('message-id').should_not be_blank
      MList::Message.last.identifier.should == remove_brackets(delivered.header_string('message-id'))
      delivered.header_string('message-id').should_not match(/F5F9DC55-CB54-4F2C-9B46-A05F241BCF22@recursivecreative\.com/)
    end

    it 'should maintain the content-id part headers (inline images, etc)' do
      @post_tmail = tmail_fixture('embedded_content')
      process_post.parts[1].parts[1]['content-id'].to_s.should == "<CF68EC17-F8ED-478A-A4A1-AEBF165A8830/bg_pattern.jpg>"
    end

    it 'should add standard list headers when they are available' do
      stub(@manager_list).help_url        {'http://list_manager.example.com/help'}
      stub(@manager_list).subscribe_url   {'http://list_manager.example.com/subscribe'}
      stub(@manager_list).unsubscribe_url {'http://list_manager.example.com/unsubscribe'}
      stub(@manager_list).owner_url       {"<mailto:list_manager@example.com>\n(Jimmy Fish)"}
      stub(@manager_list).archive_url     {'http://list_manager.example.com/archive'}

      tmail = process_post
      tmail.should have_headers(
        'list-id'          => "<list_one@example.com>",
        'list-help'        => "<http://list_manager.example.com/help>",
        'list-subscribe'   => "<http://list_manager.example.com/subscribe>",
        'list-unsubscribe' => "<http://list_manager.example.com/unsubscribe>",
        'list-post'        => "<list_one@example.com>",
        'list-owner'       => '<mailto:list_manager@example.com>(Jimmy Fish)',
        'list-archive'     => "<http://list_manager.example.com/archive>",
        'errors-to'        => '"Discussions" <mlist-list_one@example.com>',
        # I couldn't get tmail to quote 'Discussions', so apostrophe's would break smtp
        'sender'           => 'mlist-list_one@example.com'
      )
      tmail.header_string('x-mlist-version').should =~ /\d+\.\d+\.\d+/
    end

    it 'should not add list headers that are not available or nil' do
      stub(@manager_list).help_url {nil}
      delivery = process_post
      delivery.should_not have_header('list-help')
      delivery.should_not have_header('list-subscribe')
    end

    it 'should append the list footer to text/plain emails' do
      @post_tmail.body = "My Email\n\n\n\n\n"
      mock(@manager_list).footer_content(is_a(MList::Message)) { 'my footer' }
      process_post.body.should == "My Email\n\n\n\n\n#{MList::MailList::FOOTER_BLOCK_START}\nmy footer\n#{MList::MailList::FOOTER_BLOCK_END}"
    end

    it 'should append the list footer to multipart/alternative, text/plain part of emails' do
      @post_tmail = tmail_fixture('content_types/multipart_alternative_simple')
      mock(@manager_list).footer_content(is_a(MList::Message)) { 'my footer' }
      process_post.parts[0].body.should match(/#{MList::MailList::FOOTER_BLOCK_START}\nmy footer\n#{MList::MailList::FOOTER_BLOCK_END}/)
    end

    it 'should append the list footer to multipart/alternative, text/html part of emails' do
      @post_tmail = tmail_fixture('content_types/multipart_alternative_simple')
      mock(@manager_list).footer_content(is_a(MList::Message)) { "my footer\nis here\nhttp://links/here" }
      process_post.parts[1].body.should match(/<p>#{MList::MailList::FOOTER_BLOCK_START}<br \/>\nmy footer<br \/>\nis here<br \/>\n<a href="http:\/\/links\/here">http:\/\/links\/here<\/a><br \/>\n#{MList::MailList::FOOTER_BLOCK_END}<\/p>/)
    end

    it 'should handle whitespace well when appending footer' do
      @post_tmail.body = "My Email"
      mock(@manager_list).footer_content(is_a(MList::Message)) { 'my footer' }
      process_post.body.should == "My Email\n\n#{MList::MailList::FOOTER_BLOCK_START}\nmy footer\n#{MList::MailList::FOOTER_BLOCK_END}"
    end

    it 'should strip out any existing text footers from the list' do
      mock(@manager_list).footer_content(is_a(MList::Message)) { 'my footer' }
      @post_tmail.body = %{My Email

>  >  #{MList::MailList::FOOTER_BLOCK_START}
>     >  content at front shouldn't matter
>      >  #{MList::MailList::FOOTER_BLOCK_END}

>>  #{MList::MailList::FOOTER_BLOCK_START}
>>  this is fine to be removed
>>  #{MList::MailList::FOOTER_BLOCK_END}

#{MList::MailList::FOOTER_BLOCK_START}
this is without any in front
#{MList::MailList::FOOTER_BLOCK_END}
      }
      process_post.body.should == "My Email\n\n#{MList::MailList::FOOTER_BLOCK_START}\nmy footer\n#{MList::MailList::FOOTER_BLOCK_END}"
    end

    it 'should strip out any existing html footers from the list' do
      @post_tmail = tmail_fixture('content_types/multipart_alternative_simple')
      mock(@manager_list).footer_content(is_a(MList::Message)) { 'my footer' }
      @post_tmail.parts[1].body = %{<p>My Email</p>
<blockquote>
   <p> Stuff in my email</p><p>  #{MList::MailList::FOOTER_BLOCK_START}
>     >  content at front shouldn't matter
>      >  #{MList::MailList::FOOTER_BLOCK_END}  </p>

>>  not in our p!<p>#{MList::MailList::FOOTER_BLOCK_START}
>>  this is fine to be removed
>>  #{MList::MailList::FOOTER_BLOCK_END}</p>

<p>#{MList::MailList::FOOTER_BLOCK_START}
this is without any in front
#{MList::MailList::FOOTER_BLOCK_END}
</p>
      }
      process_post.parts[1].body.should == "<p>My Email</p>\n<blockquote>\n   <p> Stuff in my email</p>\n\n>>  not in our p!<p>#{MList::MailList::FOOTER_BLOCK_START}<br />\nmy footer<br />\n#{MList::MailList::FOOTER_BLOCK_END}</p>"
    end

    it 'should properly reflect the new encoding when adding footers' do
      @post_tmail = tmail_fixture('content_types/multipart_alternative_encoded')
      stub(@manager_list).footer_content { 'my footer' }

      part = process_post.parts[0]
      part.charset.should == 'utf-8'
      part.body.should == "Hi Friends and Neighbors:\n\nLike you, we have many concerns about what is going on in our country.  This\nyear in our homeschool, we've spent a lot more time learning about the\nhistory of our country, and the mindset of the founders that caused them to\nbreak away from the British empire and put together our great founding\ndocuments of the Declaration of Independence and U.S. Constitution.  How far\nwe have fallen!\n\n-- \nBob Bold\nThe Edge of Your Seat Experience Compny™\n\n\n#{MList::MailList::FOOTER_BLOCK_START}\nmy footer\n#{MList::MailList::FOOTER_BLOCK_END}"

      part = process_post.parts[1]
      part.charset.should == 'utf-8'
      part.body.should == "<div class=\"gmail_quote\"><br><div class=\"gmail_quote\"><div><span style=\"font-family:arial, sans-serif;font-size:13px;border-collapse:collapse\"><div>\nHi Friends and Neighbors:</div><div><br></div><div>Like you, we have many concerns about what is going on in our country.  This year in our homeschool, we&#39;ve spent a lot more time learning about the history of our country, and the mindset of the founders that caused them to break away from the British empire and put together our great founding documents of the Declaration of Independence and U.S. Constitution.  How far we have fallen!</div>\n\n<div><span style=\"font-size:small\"><br></span></div></span></div></div>-- <br>Bob Bold<br>The Edge of Your Seat Experience Compny™ <br>Beaverton Heights               919-555-5555 (v)<br>1234 Checkstone St            919-555-5555 (f)<br><p>#{MList::MailList::FOOTER_BLOCK_START}<br />\nmy footer<br />\n#{MList::MailList::FOOTER_BLOCK_END}</p>"
    end

    describe 'time' do
      include TMail::TextUtils

      before do
        @old_zone_default = Time.zone_default
        @system_time = Time.parse('Thu, 2 Apr 2009 15:22:04')
        mock(Time).now.times(any_times) { @system_time }
      end

      after do
        Time.zone_default = @old_zone_default
      end

      it 'should keep date of email post' do
        @post_tmail['date'] = 'Thu, 2 Apr 2009 15:22:04 -0400'
        process_post.header_string('date').should == 'Thu, 2 Apr 2009 15:22:04 -0400'
      end

      it 'should store the delivery time as created_at of message record' do
        Time.zone_default = 'Pacific Time (US & Canada)'
        @post_tmail['date'] = 'Wed, 1 Apr 2009 15:22:04 -0400'
        process_post.header_string('date').should == 'Wed, 1 Apr 2009 15:22:04 -0400'
        MList::Message.last.created_at.should == @system_time
      end

      # I think that what TMail is doing is evil, but it's reference to
      # a ruby-talk discussion leads to Japanese, which I cannot read.
      # I'd prefer that it leave the problem of timezones up to the client,
      # especially since ActiveSupport does an EXCELLENT job of making
      # time zones not hurt so much.
      it 'should use the Time.now (zone of the machine) for date header' do
        @post_tmail['date'] = nil
        process_post.header_string('date').should == time2str(@system_time)
      end
    end
  end
end
