# frozen_string_literal: true

require "parser"

require_relative "code_histogram"

class NodeTypeCounter < Parser::Rewriter
  attr_reader :node_types

  def initialize(filename)
    @node_types = CodeHistogram.new
    @filename = filename
  end

  def process(node)
    return if node.nil?
    @node_types.increment(node.type)
    super
  end

  def print(io)
    parser = Parser::CurrentRuby.new
    buffer = Parser::Source::Buffer.new(@filename)
    buffer.read
    ast = parser.parse(buffer)

    process(ast)

    @node_types.print_by_frequency(io)
  end
end
