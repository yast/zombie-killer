# -*- ruby -*-

Gem::Specification.new do |spec|

  # gem name and description
  spec.name	= "zombie-killer"
  spec.version	= "0.1.0"
  spec.summary = "Translate YCP-like library calls (Ops.*, Builtins.*) to idiomatic Ruby"
  spec.license  = "MIT"
  spec.authors	= ["Martin Vidner", "David Majda"]
  spec.homepage	= "http://github.org/yast/zombie-killer"

  # gem content
  spec.files   = Dir["lib/**/*.rb", "spec/*.md", "LICENSE"]

  # define LOAD_PATH
  spec.require_path = "lib"

  # dependencies
  spec.add_dependency "parser"
  spec.add_dependency "unparser"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "redcarpet"
end
