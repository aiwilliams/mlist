module MList
  class Thread < ActiveRecord::Base
    set_table_name 'mlist_threads'
    
    belongs_to :mail_list, :class_name => 'MList::MailList', :counter_cache => :threads_count
    has_many :messages, :class_name => 'MList::Message', :dependent => :delete_all
    
    def children(message)
      messages.select {|m| m.parent == message}
    end
    
    def first?(message)
      messages.first == message
    end
    
    def last?(message)
      messages.last == message
    end
    
    def next(message)
      i = messages.index(message)
      messages[i + 1] unless messages.size < i
    end
    
    def previous(message)
      i = messages.index(message)
      messages[i - 1] if i > 0
    end
    
    def roots
      messages.select {|m| m.parent.nil?}
    end
    
    def subject
      messages.first.subject
    end
  end
end