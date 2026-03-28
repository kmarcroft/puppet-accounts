# frozen_string_literal: true

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.mock_with :rspec
  c.hiera_config = 'spec/fixtures/hiera/hiera.yaml'
  c.module_path  = File.join(fixture_path, 'modules')
end

at_exit { RSpec::Puppet::Coverage.report! }
