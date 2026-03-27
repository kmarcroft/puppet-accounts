# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'
require 'metadata-json-lint/rake_task'

begin
  require 'puppet_blacksmith/rake_tasks'
rescue LoadError
  # puppet-blacksmith is optional (development group)
end

desc 'Lint metadata.json file'
task :meta do
  sh 'metadata-json-lint metadata.json'
end

exclude_paths = [
  'bundle/**/*',
  'pkg/**/*',
  'vendor/**/*',
  'spec/**/*',
]

PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths
  config.log_format = '%{path}:%{linenumber}:%{KIND}: %{message}'
end

PuppetSyntax.exclude_paths = exclude_paths

desc 'Run acceptance tests'
RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/acceptance/*_spec.rb'
end

desc 'Populate CONTRIBUTORS file'
task :contributors do
  system("git log --format='%aN' | sort -u > CONTRIBUTORS")
end

task default: [:lint, :syntax, :spec]
