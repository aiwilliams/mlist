module MList
  class Thread < ActiveRecord::Base
    set_table_name 'mlist_threads'
    
    belongs_to :mail_list, :class_name => 'MList::MailList', :counter_cache => :threads_count
    has_many :messages, :class_name => 'MList::Message', :dependent => :delete_all
    
    def subject
      messages.first.subject
    end
    
    # Answers a tree of messages.
    #
    # The nodes of the tree are decorated to act like a linked list, providing
    # pointers to _next_ and _previous_ in the tree.
    #
    def tree
      return nil if messages.size == 0
      
      nodes = messages.collect do |m|
        m.parent = messages.detect {|pm| pm.id == m.parent_id}
        Node.new(m)
      end
      
      nodes.each do |node|
        if parent_node = nodes.detect {|n| n == node.parent}
          node.parent_node = parent_node
          parent_node.children << node
        end
      end
      
      previous_node = nil
      nodes.first.visit do |node|
        if previous_node
          node.previous = previous_node
          previous_node.next = node
        end
        previous_node = node
      end
      
      nodes.first
    end
    
    class Node < DelegateClass(Message)
      attr_accessor :parent_node, :previous, :next
      attr_reader :children
      
      def initialize(message)
        super
        @children = []
      end
      
      def leaf?
        children.empty?
      end
      
      def root?
        parent_node.nil?
      end
      
      def visit(&visitor)
        visitor.call self
        children.each {|c| c.visit(&visitor)}
      end
    end
    
  end
end