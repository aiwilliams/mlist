require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MList::Util::EmailHelpers do
  include MList::Util::EmailHelpers
  
  %w(nothing_special ascii_art reply_quoting bullets bullets_leading_space).each do |text_source_name|
    specify "text_to_html should convert #{text_source_name}" do
      source_text = text_fixture(text_source_name)
      expected_text = text_fixture("#{text_source_name}.html")
      text_to_html(source_text).should == expected_text
    end
  end
  
  specify 'text_to_quoted should prepend >' do
    text_to_quoted(text_fixture('nothing_special')).should == text_fixture('nothing_special_quoted')
  end
end