ActiveRecord::Schema.define(:version => 20081126181722) do
  create_table :lists, :force => true do |t|
    t.column :address, :string
    t.column :created_at, :datetime
  end
  
  create_table :subscriptions, :force => true do |t|
    t.column :list_id, :integer
    t.column :address, :string
    t.column :created_at, :datetime
  end
  
  create_table :mails, :force => true do |t|
    t.column :thread_id, :integer
    t.column :email_text, :text
  end
  
  create_table :threads, :force => true do |t|
  end
end
