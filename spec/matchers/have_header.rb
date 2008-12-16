module Spec
  module Matchers
    
    class HaveHeader
      def initialize(name, expected)
        @name, @expected = name, expected
      end
      
      def matches?(email)
        @given = email
        
        if @expected.blank?
          if !@given[@name.downcase]
            @failure_message = "expected header #{@name.inspect} to be present but it was not"
          end
        else
          missing = expected_values.reject {|e| header_values.include?(e)}
          extra = header_values.reject {|e| expected_values.include?(e)}
          unless extra.empty? && missing.empty?
            @failure_message = "expected header #{@name.inspect} to be equal but was not"
            @failure_message << "\nmissing in given: #{missing.inspect}" unless missing.empty?
            @failure_message << "\nextra in given: #{extra.inspect}" unless extra.empty?
          end
        end
        
        @failure_message.nil?
      end
      
      def failure_message
        @failure_message
      end
      
      def negative_failure_message
        if @expected.blank? && @given[@name.downcase]
          "expected header #{@name.inspect} to not be present but was"
        else
          "expected header #{@name.inspect} to not be equal but it was"
        end
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
        
        def header_values
          values = []
          @given.each_header do |k,v|
            values << v.to_s.strip if k.downcase == @name.downcase
          end
          values
        end
    end
    
    def have_header(name, expected = nil)
      HaveHeader.new(name, expected)
    end
  end
end