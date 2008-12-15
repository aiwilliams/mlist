module MList
  class Thread < ActiveRecord::Base
    has_many :mails
  end
end