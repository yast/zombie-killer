require "parser"
require "parser/current"

require_relative "eager_rewriter"
require_relative "rewriter"

# The main class called from the CLI
class ZombieKiller
  # @return [Boolean] use the EagerRewriter
  attr_reader :eager

  def initialize(eager: false)
    @eager = eager
  end

  # @param code [String]
  # @param filename [String]
  # @returns new string
  def kill_string(code, filename = "(inline code)", unsafe: false)
    fixed_point(code) do |c|
      parser   = Parser::CurrentRuby.new
      rewriter = eager ? EagerRewriter.new : ZombieKillerRewriter.new(unsafe: unsafe)
      buffer   = Parser::Source::Buffer.new(filename)
      buffer.source = c
      rewriter.rewrite(buffer, parser.parse(buffer))
    end
  end
  alias_method :kill, :kill_string

  # @param new_filename may be the same as *filename*
  def kill_file(filename, new_filename, unsafe: false)
    new_string = kill_string(File.read(filename), filename, unsafe: unsafe)

    File.write(new_filename, new_string)
  end

  private

  def fixed_point(x, &lambda_x)
    while true
      y = lambda_x.call(x)
      return y if y == x
      x = y
    end
  end
end
