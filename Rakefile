# frozen_string_literal: true

require 'bundler'
Bundler.setup

require 'rake'
require 'rspec/core/rake_task'
require 'rubygems/package_task'
require 'rubocop/rake_task'

task default: %i[spec rubocop]

desc 'Run all rspec files'
RSpec::Core::RakeTask.new('spec') do |c|
  c.rspec_opts = '-t ~unresolved'
end

spec = Gem::Specification.load 'rotating_es_loader.gemspec'
Gem::PackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

RuboCop::RakeTask.new
