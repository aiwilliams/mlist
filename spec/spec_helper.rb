SPEC_ROOT = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << (SPEC_ROOT + '/../lib')

require 'rubygems'
require 'spec'
require 'rr'
require 'ostruct'

Spec::Runner.configure do |config|
  config.mock_with :rr
end

Dir[SPEC_ROOT + '/matchers/*.rb'].each { |path| require path }

require 'activerecord'
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

def email_fixtures_path(path)
  File.join(SPEC_ROOT, 'fixtures/email', path)
end

def email_fixture(path)
  File.read(email_fixtures_path(path))
end

def tmail_fixture(path)
  TMail::Mail.parse(email_fixture(path))
end

require 'mlist'