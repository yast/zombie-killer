$:.unshift File.expand_path("../../lib", __FILE__)
require "zombie_killer"

def cleanup(s)
  s.split("\n").reject { |l| l =~ /^\s*$/ }.first =~ /^(\s*)/
  s.gsub(Regexp.new("^#{$1}"), "")[0..-2]
end
