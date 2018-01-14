# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "sharder/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "sharder"
  s.version     = Sharder::VERSION
  s.authors     = ["Hayden Ball"]
  s.email       = ["hayden@haydenball.me.uk"]

  s.summary       = "Dynamic Rails database sharding"
  s.homepage      = "TODO: Put your gem's website or public repo URL here."
  s.license       = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.1.0"

  s.add_development_dependency "pg", "~> 0.18"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "appraisal"
end
