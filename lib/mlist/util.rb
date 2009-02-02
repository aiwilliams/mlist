require 'mlist/util/quoting'
require 'mlist/util/header_sanitizer'
require 'mlist/util/email_helpers'
require 'mlist/util/tmail_methods'
require 'mlist/util/tmail_adapter'

module MList
  module Util
    mattr_accessor :default_header_sanitizers
    self.default_header_sanitizers = HeaderSanitizerHash.new
  end
end