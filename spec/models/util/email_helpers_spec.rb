require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe MList::Util::EmailHelpers do
  include MList::Util::EmailHelpers
  
  %w(nothing_special ascii_art reply_quoting reply_quoting_deeper bullets bullets_leading_space).each do |text_source_name|
    specify "text_to_html should convert #{text_source_name}" do
      source_text = text_fixture(text_source_name)
      expected_text = text_fixture("#{text_source_name}.html")
      text_to_html(source_text).should == expected_text
    end
  end
  
  specify 'text_to_quoted should prepend >' do
    text_to_quoted(text_fixture('nothing_special')).should == text_fixture('nothing_special_quoted')
  end
  
  describe 'remove_regard' do
    it 'should remove regardless of case' do
      remove_regard('Re: [Label] Subject').should == '[Label] Subject'
      remove_regard('RE: [Label] Subject').should == '[Label] Subject'
    end
    
    it 'should not bother [] labels when multiple re:' do
      remove_regard('Re: [Label] Re: Subject').should == '[Label] Subject'
    end
    
    it 'should remove multiple re:' do
      remove_regard('Re: Re: Test').should == 'Test'
      remove_regard('Re:  Re: Subject').should == 'Subject'
    end
  end
  
  describe 'html_to_text' do
    it 'should handle real life example' do
      html_to_text(html_fixture('real_life')).should == html_fixture('real_life.txt')
    end
    
    it 'should handle lists' do
      html_to_text('<p>Fruits</p>  <ul><li>Apples</li><li>Oranges</li><li>Bananas</li></ul>').should == %{Fruits\n\n * Apples\n\n * Oranges\n\n * Bananas}
    end
    
    it 'should handle lots of non-breaking space' do
      html_to_text(html_fixture('nbsp')).should == html_fixture('nbsp.txt')
    end
  end
end