require 'net/imap'

module MList
  module EmailServer

    class Imap < Base
      def initialize(settings)
        super(settings)
      end

      def deliver(tmail)
        raise "Mail delivery is not presently supported by the Imap server. Please use the '#{MList::EmailServer::Default.name}' type."
      end

      def execute
        begin
          connect
          process_folders
        ensure
          disconnect
        end
      end

      def archive_message_id(id)
        @imap.copy(id, settings[:archive_folder])
        @imap.store(id, '+FLAGS', [:Deleted])
      end

      def connect
        @imap = Net::IMAP.new(
          settings[:server],
          settings[:port],
          settings[:ssl]
        )
        @imap.login(settings[:username], settings[:password])
      end

      def disconnect
        @imap.disconnect if @imap && !@imap.disconnected?
      end

      def process_folders
        Array(settings[:source_folders]).each do |folder|
          process_folder(folder)
        end
      end

      def process_folder(folder)
        @imap.select(folder)
        @imap.search(['NOT','DELETED']).each do |message_id|
          process_message_id(message_id)
          archive_message_id(message_id)
        end
        @imap.close
      end

      def process_message_id(id)
        content = @imap.fetch(id, 'RFC822')[0].attr['RFC822']
        process_message(content)
      end

      def process_message(content)
        receive(TMail::Mail.parse(content))
      end
    end

  end
end
