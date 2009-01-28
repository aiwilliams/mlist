ActiveRecord::Schema.define(:version => 20081126181722) do
  
  # All MList required tables are prefixed with 'mlist_' to ease integration
  # into other systems' databases.
  
  
  # The table in which MList will store MList::Messages.
  #
  # The identifier is the 'message-id' header value.
  #
  # An MList::Message will store a reference to your application's subscriber
  # instance if it is an ActiveRecord subclass. That subclass must respond to
  # :email_address. If your subscriber is just a string, it is assumed to be
  # an email address. Either way, that email address will be stored with the
  # MList::Message, providing a way for you associate messages by
  # subscriber_address.
  #
  create_table :mlist_messages, :force => true do |t|
    t.column :mail_list_id, :integer
    t.column :thread_id, :integer
    t.column :identifier, :string
    t.column :subject, :string
    t.column :email_text, :text
    t.column :subscriber_address, :string
    t.column :subscriber_type, :string
    t.column :subscriber_id, :integer
    t.column :created_at, :datetime
  end
  add_index :mlist_messages, :mail_list_id
  add_index :mlist_messages, :thread_id
  add_index :mlist_messages, :identifier
  add_index :mlist_messages, :subject
  add_index :mlist_messages, :subscriber_address
  add_index :mlist_messages, [:subscriber_type, :subscriber_id]
  
  # Every MList::Message is associated with an MList::Thread.
  #
  create_table :mlist_threads, :force => true do |t|
    t.column :mail_list_id, :integer
    t.timestamps
  end
  add_index :mlist_threads, :mail_list_id
  
  # The table in which MList will store MList::MailLists.
  #
  # The manager_list_identifier column stores the MList::List#list_id value.
  # This is a connection to the application's implementation of MList::List.
  # These identifiers must be unique and never change for an MList::List.
  #
  # An MList::MailList will store a reference to your application's
  # MList::List instance if it is an ActiveRecord subclass.
  #
  create_table :mlist_mail_lists, :force => true do |t|
    t.column :manager_list_identifier, :string
    t.column :manager_list_type, :string
    t.column :manager_list_id, :integer
    t.timestamps
  end
  add_index :mlist_mail_lists, :manager_list_identifier
  add_index :mlist_mail_lists, [:manager_list_identifier, :manager_list_type, :manager_list_id],
    :name => :index_mlist_mail_lists_on_manager_association
  
  
  # Database list manager tables, used for testing purposes.
  #
  create_table :lists, :force => true do |t|
    t.column :address, :string
    t.column :label, :string
    t.column :created_at, :datetime
  end
  
  create_table :subscribers, :force => true do |t|
    t.column :list_id, :integer
    t.column :email_address, :string
    t.column :created_at, :datetime
  end
end
