#!/usr/bin/env rake
require 'bundler/setup'
require 'bundler/gem_tasks'

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'README.md']
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

