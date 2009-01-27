module MList
  class Thread < ActiveRecord::Base
    set_table_name 'mlist_threads'
    
    belongs_to :mail_list
    has_many :messages, :dependent => :delete_all
  end
end