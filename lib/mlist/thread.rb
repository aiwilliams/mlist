module MList
  class Thread < ActiveRecord::Base
    set_table_name 'mlist_threads'
    
    belongs_to :mail_list, :class_name => 'MList::MailList'
    has_many :messages, :class_name => 'MList::Message', :dependent => :delete_all
  end
end