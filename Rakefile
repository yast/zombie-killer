# frozen_string_literal: true

require "rspec/core/rake_task"

require "redcarpet"
require_relative "spec/rspec_renderer"

def render_markdown(renderer_class, task)
  markdown = Redcarpet::Markdown.new(renderer_class, fenced_code_blocks: true)

  string = markdown.render(File.read(task.prerequisites[0]))
  File.write(task.name, string)
end

file "spec/zombie_killer_spec.rb" => "spec/zombie_killer_spec.md" do |t|
  render_markdown(RSpecRenderer, t)
end

file "spec/zombie_killer_spec.html" => "spec/zombie_killer_spec.md" do |t|
  render_markdown(Redcarpet::Render::HTML, t)
end
desc "Render the specification locally"
task html: ["spec/zombie_killer_spec.html"]

RSpec::Core::RakeTask.new do |t|
  t.verbose = false
end
task spec: ["spec/zombie_killer_spec.rb"]

task default: :spec
