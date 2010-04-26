require 'rubygems'
require 'spec'
gem 'rr', '0.10.0'
require 'rr'
require 'ostruct'

Spec::Runner.configure do |config|
  config.mock_with :rr
end

SPEC_ROOT = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift(SPEC_ROOT + '/../lib')
Dir[SPEC_ROOT + '/matchers/*.rb'].each { |path| require path }

require 'active_record'
SQLITE_DATABASE = "#{SPEC_ROOT}/sqlite3.db"
ActiveRecord::Base.silence do
  ActiveRecord::Base.configurations = {'test' => {
    'adapter' => 'sqlite3',
    'database' => SQLITE_DATABASE
  }}
  ActiveRecord::Base.establish_connection 'test'
  load "#{SPEC_ROOT}/fixtures/schema.rb"
end

require 'dataset'
class Spec::Example::ExampleGroup
  include Dataset
  datasets_directory "#{SPEC_ROOT}/datasets"
end

# Fixture helpers
def email_fixtures_path(path)
  File.join(SPEC_ROOT, 'fixtures/email', path)
end

def email_fixture(path)
  File.read(email_fixtures_path(path))
end

def tmail_fixture(path, header_changes = {})
  tmail = TMail::Mail.parse(email_fixture(path))
  header_changes.each do |k,v|
    tmail[k] = v
  end
  tmail
end

def html_fixtures_path(path)
  File.join(SPEC_ROOT, 'fixtures/html', path)
end

def html_fixture(path)
  File.read(html_fixtures_path(path))
end

def text_fixtures_path(path)
  File.join(SPEC_ROOT, 'fixtures/text', path)
end

def text_fixture(path)
  File.read(text_fixtures_path(path))
end

# To see the output of an email in your client, this will use sendmail to
# deliver the email to the given address. It shouldn't be sent to the
# addresses in to: cc: or bcc:, I hope.
#
def visualize_email(email, recipient_address)
  tf = Tempfile.new('email_visualize')
  tf.puts email.to_s
  tf.close
  `cat #{tf.path} | sendmail -t #{recipient_address}`
end

require 'mlist'
require 'mlist/email_server/fake'
