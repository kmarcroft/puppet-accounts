# frozen_string_literal: true

source 'https://rubygems.org'

gem 'puppet', ENV['PUPPET_VERSION'] || ['>= 7.0', '< 9.0']
gem 'json_pure', '>= 2.7.0'

group :test do
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'rspec-puppet', '>= 4.0'
  gem 'puppetlabs_spec_helper', '>= 6.0'
  gem 'rspec-puppet-facts', '>= 2.0'
  gem 'simplecov', '>= 0.21.0'
  gem 'simplecov-console'
  gem 'deep_merge'
  gem 'metadata-json-lint', '>= 3.0'
  gem 'rubocop', '>= 1.50'
  gem 'rubocop-performance'
  gem 'puppet-lint', '>= 3.0'
  gem 'puppet-syntax', '>= 3.2'
  gem 'voxpupuli-test', '>= 7.0'
end

group :development do
  gem 'pdk', '>= 3.0'
  gem 'puppet-blacksmith', '>= 6.0'
  gem 'github_changelog_generator', '>= 1.16'
end

group :system_tests do
  gem 'puppet_litmus', '>= 1.0'
end
