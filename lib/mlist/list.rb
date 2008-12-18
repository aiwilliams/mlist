module MList
  module List
    def host
      address.match(/@(.*)\Z/)[1]
    end
    
    def list_id
      "#{label} <#{address}>"
    end
    
    def name
      address.match(/\A(.*?)@/)[1]
    end
    
    def post_url
      address
    end
  end
end