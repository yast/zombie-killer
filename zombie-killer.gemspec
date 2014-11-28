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
  spec.homepage = "http://github.org/yast/zombie-killer"

  # gem content
  spec.files    = Dir[
    "LICENSE",
    "README.md",
    "bin/zk",
    "lib/**/*.rb",
    "spec/*.md",
    "spec/*.rb",
  ]
  spec.executables = ["zk"]

  # define LOAD_PATH
  spec.require_path = "lib"

  # dependencies
  spec.add_dependency "docopt",   "~> 0"
  spec.add_dependency "parser",   "> 2.2.0.pre.5", "< 3"
  spec.add_dependency "unparser", "~> 0"

  spec.add_development_dependency "rspec",     "> 2", "< 4"
  spec.add_development_dependency "redcarpet", "~> 3"
end
