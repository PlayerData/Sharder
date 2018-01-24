# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sharder/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sharder"
  s.version     = Sharder::VERSION
  s.authors     = ["Hayden Ball"]
  s.email       = ["hayden@playerdata.co.uk"]

  s.summary       = "Dynamic Database Sharding for Rails"
  s.homepage      = "https://github.com/playerdata/sharder"
  s.license       = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.1.0"
  s.add_dependency "concurrent-ruby"

  s.add_development_dependency "appraisal"
  s.add_development_dependency "pg", "~> 0.18"
  s.add_development_dependency "rspec-rails"
end
