# -*- ruby -*-
require "rspec/core/rake_task"

require_relative "spec/rspec_renderer"

file "spec/zombie_killer_spec.rb" => "spec/zombie_killer_spec.md" do |t|
  markdown = Redcarpet::Markdown.new(RSpecRenderer, fenced_code_blocks: true)

  puts t.name
  File.open(t.name, "w") do |f|
    f.write(markdown.render(File.read(t.prerequisites[0])))
  end
end

RSpec::Core::RakeTask.new
task :spec => ["spec/zombie_killer_spec.rb"]

task :default => :spec
