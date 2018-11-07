# frozen_string_literal: true

# -*- ruby -*-
require File.expand_path("../lib/zombie_killer/version", __FILE__)

Gem::Specification.new do |spec|
  # gem name and description
  spec.name     = "zombie-killer"
  spec.version  = ZombieKiller::VERSION
  spec.summary  = "Resocialize YCP Zombies"
  spec.description =
    "Translate YCP-like library calls (Ops.*, Builtins.*) to idiomatic Ruby"
  spec.license  = "MIT"
  spec.authors  = ["Martin Vidner", "David Majda"]
  spec.email    = ["martin@vidner.net", "david@majda.cz"]
  spec.homepage = "https://github.com/yast/zombie-killer"

  # gem content
  spec.files    = Dir[
    "LICENSE",
    "NEWS.md",
    "README.md",
    "bin/count_method_calls",
    "bin/zk",
    "lib/**/*.rb",
    "spec/*.md",
    "spec/*.rb",
  ]
  spec.executables = ["zk", "count_method_calls"]

  # define LOAD_PATH
  spec.require_path = "lib"

  # dependencies
  spec.add_dependency "docopt",   "~> 0"
  spec.add_dependency "parser",   ">= 2.2.0", "< 3"
  spec.add_dependency "unparser", "~> 0"

  spec.add_development_dependency "coveralls", "~> 0"
  spec.add_development_dependency "rake", ">=10", "< 999"
  spec.add_development_dependency "rspec",     "> 2", "< 4"
  spec.add_development_dependency "redcarpet", "~> 3"
  spec.add_development_dependency "rubocop", "= 0.41.2"
  spec.add_development_dependency "simplecov", "~> 0"
end
