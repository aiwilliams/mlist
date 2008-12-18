module MList
  class Thread < ActiveRecord::Base
    belongs_to :mail_list
    has_many :mails, :dependent => :delete_all
  end
end