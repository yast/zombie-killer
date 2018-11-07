# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start

  top_location = File.expand_path("../../", __FILE__)
  # track all ruby files under lib
  SimpleCov.track_files("#{top_location}/lib/**/*.rb")

  # use coveralls for on-line code coverage reporting at Travis CI
  if ENV["TRAVIS"]
    require "coveralls"
    SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter
    ]
  end
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "zombie_killer"

def cleanup(s)
  s.split("\n").reject { |l| l =~ /^\s*$/ }.first =~ /^(\s*)/
  s.gsub(Regexp.new("^#{Regexp.last_match(1)}"), "")[0..-2]
end
