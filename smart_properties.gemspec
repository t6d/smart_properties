# -*- encoding: utf-8 -*-
require File.expand_path('../lib/smart_properties/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Konstantin Tennhard"]
  gem.email         = ["me@t6d.de"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "smart_properties"
  gem.require_paths = ["lib"]
  gem.version       = SmartProperties::VERSION
  
  gem.add_development_dependency "rspec", "~> 2.0"
end
