require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

require 'tempfile'

describe MList::Util::Quoting do
  # Move some tests from TMAIL here
  it 'should unquote quoted printable' do
    a ="=?ISO-8859-1?Q?[166417]_Bekr=E6ftelse_fra_Rejsefeber?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    b.should == "[166417] Bekr\303\246ftelse fra Rejsefeber"
  end

  it 'should unquote base64' do
    a ="=?ISO-8859-1?B?WzE2NjQxN10gQmVrcuZmdGVsc2UgZnJhIFJlanNlZmViZXI=?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    b.should == "[166417] Bekr\303\246ftelse fra Rejsefeber"
  end

  it 'should unquote without charset' do
    a ="[166417]_Bekr=E6ftelse_fra_Rejsefeber"
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    b.should == "[166417]_Bekr=E6ftelse_fra_Rejsefeber"
  end

  it 'should unqoute multiple' do
    a ="=?utf-8?q?Re=3A_=5B12=5D_=23137=3A_Inkonsistente_verwendung_von_=22Hin?==?utf-8?b?enVmw7xnZW4i?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    b.should == "Re: [12] #137: Inkonsistente verwendung von \"Hinzuf\303\274gen\""
  end

  it 'should unqoute in the middle' do
    a ="Re: Photos =?ISO-8859-1?Q?Brosch=FCre_Rand?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'utf-8')
    b.should == "Re: Photos Brosch\303\274re Rand"
  end

  it 'should unqoute iso' do
    a ="=?ISO-8859-1?Q?Brosch=FCre_Rand?="
    b = TMail::Unquoter.unquote_and_convert_to(a, 'iso-8859-1')
    expected = "Brosch\374re Rand"
    expected.force_encoding 'iso-8859-1' if expected.respond_to?(:force_encoding)
    b.should == expected
  end

  it 'should quote multibyte chars' do
    original = "\303\246 \303\270 and \303\245"
    original.force_encoding('ASCII-8BIT') if original.respond_to?(:force_encoding)

    result = execute_in_sandbox(<<-CODE)
      $:.unshift(File.dirname(__FILE__) + "/../../../lib/")
      $KCODE = 'u'
      require 'jcode'
      require 'mlist/util/quoting'
      include MList::Util::Quoting
      quoted_printable("UTF-8", #{original.inspect})
    CODE

    unquoted = TMail::Unquoter.unquote_and_convert_to(result, nil)
    unquoted.should == original
  end

  # test an email that has been created using \r\n newlines, instead of
  # \n newlines.
  it 'should email quoted with 0d0a' do
    mail = TMail::Mail.parse(IO.read("#{SPEC_ROOT}/fixtures/email/raw_email_quoted_with_0d0a"))
    mail.body.should match(%r{Elapsed time})
  end

  it 'should email with partially quoted subject' do
    mail = TMail::Mail.parse(IO.read("#{SPEC_ROOT}/fixtures/email/raw_email_with_partially_quoted_subject"))
    mail.subject.should == "Re: Test: \"\346\274\242\345\255\227\" mid \"\346\274\242\345\255\227\" tail"
  end

  private
    # This whole thing *could* be much simpler, but I don't think Tempfile,
    # popen and others exist on all platforms (like Windows).
    def execute_in_sandbox(code)
      test_name = "#{File.dirname(__FILE__)}/am-quoting-test.#{$$}.rb"
      res_name = "#{File.dirname(__FILE__)}/am-quoting-test.#{$$}.out"

      File.open(test_name, "w+") do |file|
        file.write(<<-CODE)
          block = Proc.new do
            #{code}
          end
          puts block.call
        CODE
      end

      system("ruby #{test_name} > #{res_name}") or raise "could not run test in sandbox"
      File.read(res_name).chomp
    ensure
      File.delete(test_name) rescue nil
      File.delete(res_name) rescue nil
    end
end
