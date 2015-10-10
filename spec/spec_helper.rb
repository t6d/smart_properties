require 'bundler/setup'
require 'rspec'
require 'pry'

require 'smart_properties'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config|
end
