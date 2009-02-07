# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mlist}
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Williams"]
  s.date = %q{2009-02-07}
  s.description = %q{A Ruby mailing list library designed to be integrated into other applications.}
  s.email = %q{adam@thewilliams.ws}
  s.files = ["CHANGELOG", "Rakefile", "README", "VERSION.yml", "lib/mlist", "lib/mlist/email.rb", "lib/mlist/email_post.rb", "lib/mlist/email_server", "lib/mlist/email_server/base.rb", "lib/mlist/email_server/default.rb", "lib/mlist/email_server/fake.rb", "lib/mlist/email_server/pop.rb", "lib/mlist/email_server/smtp.rb", "lib/mlist/email_server.rb", "lib/mlist/email_subscriber.rb", "lib/mlist/list.rb", "lib/mlist/mail_list.rb", "lib/mlist/manager", "lib/mlist/manager/database.rb", "lib/mlist/message.rb", "lib/mlist/server.rb", "lib/mlist/thread.rb", "lib/mlist/util", "lib/mlist/util/email_helpers.rb", "lib/mlist/util/header_sanitizer.rb", "lib/mlist/util/quoting.rb", "lib/mlist/util/tmail_builder.rb", "lib/mlist/util/tmail_methods.rb", "lib/mlist/util.rb", "lib/mlist.rb", "lib/pop_ssl.rb"]
  s.homepage = %q{http://github.com/aiwilliams/mlist}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A Ruby mailing list library designed to be integrated into other applications.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
