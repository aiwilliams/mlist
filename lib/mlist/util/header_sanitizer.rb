module MList
  module Util
    
    class QuotingSanitizer
      include Quoting
      
      def initialize(method, bracket_urls)
        @method, @bracket_urls = method, bracket_urls
      end
      
      def bracket_urls(values)
        values.map do |value|
          if value.include?('<') && value.include?('>')
            value
          else
            "<#{value}>"
          end
        end
      end
      
      def call(charset, *values)
        values = bracket_urls(values.flatten) if @bracket_urls
        send(@method, charset, *values)
      end
    end
    
    class HeaderSanitizerHash
      def initialize
        @hash = Hash.new
        initialize_default_sanitizers
      end
      
      def initialize_default_sanitizers
        self['to']       = quoter(:quote_any_address_if_necessary)
        self['cc']       = quoter(:quote_any_address_if_necessary)
        self['bcc']      = quoter(:quote_any_address_if_necessary)
        self['from']     = quoter(:quote_any_address_if_necessary)
        self['reply-to'] = quoter(:quote_any_address_if_necessary)
        self['subject']  = quoter(:quote_any_if_necessary)
        
        self['List-Help']        = quoter(:quote_address_if_necessary)
        self['List-Subscribe']   = quoter(:quote_address_if_necessary)
        self['List-Unsubscribe'] = quoter(:quote_address_if_necessary)
        self['List-Post']        = quoter(:quote_address_if_necessary)
        self['List-Owner']       = quoter(:quote_address_if_necessary)
        self['List-Archive']     = quoter(:quote_address_if_necessary)
      end
      
      def [](key)
        @hash[key.downcase] ||= lambda { |charset, value| value }
      end
      
      def []=(key, value)
        @hash[key.downcase] = value
      end
      
      def quoter(method, bracket_urls = true)
        QuotingSanitizer.new(method, bracket_urls)
      end
    end
    
  end
end