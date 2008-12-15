module Spec
  module Matchers
    
    class HaveAddress
      def initialize(field, expected)
        @field, @expected = field, expected
      end
      
      def matches?(email)
        @actual = addresses(email)
        missing = expected_addresses.reject {|e| @actual.include?(e)}
        extra = @actual.reject {|e| expected_addresses.include?(e)}
        extra.empty? && missing.empty?
      end
      
      def failure_message
        "expected #{@field} address to contain #{expected_addresses.inspect} but was #{@actual.inspect}"
      end
      
      def negative_failure_message
        "expected #{@field} address not to contain #{expected_addresses.inspect} but it did"
      end
      
      private
        def addresses(email)
          email[@field.to_s].addrs.collect(&:address) rescue []
        end
        
        def expected_addresses
          case @expected
          when Array
            @expected.collect { |a| extract_address(a) }
          when String
            [extract_address(@expected)]
          end
        end
        
        def extract_address(string)
          address = string.sub(/.*?<(.*?)>/, '\1')
          address if address =~ /\A([^@\s]+)@(localhost|(?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
        end
    end
    
    def have_address(field, expected)
      HaveAddress.new(field, expected)
    end
  end
end