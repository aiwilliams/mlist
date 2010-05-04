require 'rubygems'
require "bundler"
Bundler.setup

require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--options', 'spec/spec.opts']
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'mlist'
    s.summary = 'A Ruby mailing list library designed to be integrated into other applications.'
    s.email = 'adam@thewilliams.ws'
    s.files = FileList["[A-Z]*", "{lib,rails}/**/*"].exclude("tmp")
    s.homepage = "http://github.com/aiwilliams/mlist"
    s.description = s.summary
    s.authors = ['Adam Williams']
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end