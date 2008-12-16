module Spec
  module Matchers
    
    class HaveHeader
      def initialize(name, expected)
        @name, @expected = name, expected
      end
      
      def matches?(email)
        @actual = header_values(email)
        missing = expected_values.reject {|e| @actual.include?(e)}
        extra = @actual.reject {|e| expected_values.include?(e)}
        unless extra.empty? && missing.empty?
          @failure_message = "expected header #{@name.inspect} to be equal but was not\n"
          @failure_message << "missing in given: #{missing.inspect}" unless missing.empty?
          @failure_message << "extra in given: #{extra.inspect}" unless extra.empty?
        end
        @failure_message.nil?
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
        
        def expected_values
          case @expected
          when Array
            @expected.collect { |e| comparable_value(e) }
          when String
            [comparable_value(@expected)]
          end
        end
        
        def header_values(email)
          values = []
          email.each_header do |k,v|
            values << v.to_s.strip if k == @name
          end
          values
        end
    end
    
    def have_header(name, expected)
      HaveHeader.new(name, expected)
    end
  end
end