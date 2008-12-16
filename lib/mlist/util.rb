require 'mlist/util/quoting'
require 'mlist/util/header_sanitizer'

module MList
  module Util
    mattr_accessor :default_header_sanitizers
    self.default_header_sanitizers = HeaderSanitizerHash.new
  end
end