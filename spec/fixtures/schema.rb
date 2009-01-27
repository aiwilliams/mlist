ActiveRecord::Schema.define(:version => 20081126181722) do
  
  # MList tables
  create_table :mlist_messages, :force => true do |t|
    t.column :mail_list_id, :integer
    t.column :thread_id, :integer
    t.column :identifier, :string
    t.column :subject, :string
    t.column :email_text, :text
    t.column :created_at, :datetime
  end
  add_index :mlist_messages, :mail_list_id
  add_index :mlist_messages, :thread_id
  add_index :mlist_messages, :identifier
  add_index :mlist_messages, :subject
  
  create_table :mlist_threads, :force => true do |t|
    t.column :mail_list_id, :integer
  end
  add_index :mlist_threads, :mail_list_id
  
  create_table :mlist_mail_lists, :force => true do |t|
    t.column :identifier, :string
  end
  add_index :mlist_mail_lists, :identifier
  
  # Database list manager tables
  create_table :lists, :force => true do |t|
    t.column :address, :string
    t.column :label, :string
    t.column :created_at, :datetime
  end
  
  create_table :subscriptions, :force => true do |t|
    t.column :list_id, :integer
    t.column :address, :string
    t.column :created_at, :datetime
  end
end
