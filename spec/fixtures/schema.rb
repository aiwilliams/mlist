ActiveRecord::Schema.define(:version => 20081126181722) do
  
  # MList tables
  create_table :mails, :force => true do |t|
    t.column :mail_list_id, :integer
    t.column :thread_id, :integer
    t.column :identifier, :string
    t.column :subject, :string
    t.column :email_text, :text
    t.column :created_at, :datetime
  end
  add_index :mails, :mail_list_id
  add_index :mails, :thread_id
  add_index :mails, :identifier
  add_index :mails, :subject
  
  create_table :threads, :force => true do |t|
    t.column :mail_list_id, :integer
  end
  add_index :threads, :mail_list_id
  
  create_table :mail_lists, :force => true do |t|
    t.column :identifier, :string
  end
  add_index :mail_lists, :identifier
  
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
