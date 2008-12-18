ActiveRecord::Schema.define(:version => 20081126181722) do
  
  # MList tables
  create_table :mails, :force => true do |t|
    t.column :mail_list_id, :integer
    t.column :thread_id, :integer
    # TODO Verify length limit on Message-Id header
    t.column :identifier, :string
    # TODO Verify length limit on Subject header
    t.column :subject, :string
    t.column :email_text, :text
    t.column :created_at, :datetime
  end
  
  create_table :threads, :force => true do |t|
    t.column :mail_list_id, :integer
  end
  
  create_table :mail_lists, :force => true do |t|
    # TODO Verify length limit on List-Id header
    t.column :identifier, :string
  end
  
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
