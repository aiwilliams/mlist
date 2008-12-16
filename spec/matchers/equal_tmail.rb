module Spec
  module Matchers
    
    class EqualTmail
      def initialize(expected)
        @expected = expected
      end
      
      def matches?(tmail)
        @given = tmail
        headers_match?
      end
      
      def failure_message
        @failure_message
      end
      
      private
        def comparable_value(value)
          case value
          when Array
            value.collect {|e| e.to_s.strip}.join(" ").strip
          when String
            value.strip
          end
        end
        
        def headers_match?
          missing = @expected.header.collect { |name, value| @given[name].nil? ? name : nil }.compact
          extra = @given.header.collect { |name, value| @expected[name].nil? ? name : nil }.compact
          if extra.empty? && missing.empty?
            unequal = []
            @expected.header.each do |name, value|
              expected_value, given_value = comparable_value(value), comparable_value(@given[name])
              unless expected_value == given_value
                unequal << "expected header #{name.inspect} to be #{expected_value.inspect} but was #{given_value.inspect}"
              end
            end
            @failure_message = unequal.join("\n") unless unequal.empty?
          else
            @failure_message = "expected tmail instances to be equal but headers were not\n"
            @failure_message << "missing in given: #{missing.inspect}" unless missing.empty?
            @failure_message << "extra in given: #{extra.inspect}" unless extra.empty?
          end
          @failure_message.nil?
        end
    end
    
    def equal_tmail(tmail)
      EqualTmail.new(tmail)
    end
  end
end