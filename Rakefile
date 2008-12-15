# -*- ruby -*-

$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'rubygems'
require 'hoe'
require 'mlist/version'
require 'spec/rake/spectask'

Hoe.new('mlist', MList::VERSION::STRING) do |p|
  p.url = 'http://github.com/aiwilliams/mlist/'
  p.description = "A Ruby mailing list library designed to be integrated into other applications."
  p.rubyforge_name = 'mlist'
  p.developer('Adam Williams', 'adam@thewilliams.ws')
end

task :default => :spec

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--options', 'spec/spec.opts']
end