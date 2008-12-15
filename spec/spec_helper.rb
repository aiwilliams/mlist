SPEC_ROOT = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH << (SPEC_ROOT + '/../lib')

require 'rubygems'
require 'spec'
require 'rr'

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

require 'mlist'